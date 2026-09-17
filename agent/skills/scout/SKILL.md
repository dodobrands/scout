---
name: scout
description: Route code-metric work on a repository to the right `scout` subcommand — type counts, file counts, string/regex occurrences, lines of code, Xcode build settings — at HEAD or replayed across git history. Trigger on broad metric intent, e.g. "how many UIViewControllers are left?", "count storyboards over the last two years", "track SwiftUI adoption in this repo", "how did our lines of code grow?", "which SWIFT_VERSION do our targets use?", "build a dashboard of codebase metrics". Five sub-skills (`scout-types`, `scout-files`, `scout-pattern`, `scout-loc`, `scout-build-settings`) cover the metric axes; this umbrella picks one and holds the rules they share.
---

# Scout skill (umbrella)

`scout` measures a repository and replays that measurement over any commits in its history. Five metric subcommands, each with its own skill.

<!-- Last verified: 2026-09 against scout post-#147 (build-settings projects field). -->

## Read the help first

Before the first real command, run `scout --help`, then `scout <subcommand> --help`.

Flag names, defaults and the subcommand list live in the help and nowhere else. **The help ships with the binary; this skill ships separately and lags behind it** — where they disagree, the help is right. A newly discovered fact about the CLI belongs in the help too, not in this skill.

This skill carries only what the help does not: config file shapes, output JSON shapes, cross-commit behaviour and footguns.

## Tooling invariant: scout owns the checkout loop

Once any of these skills is in play, **run every historical measurement through `scout`**. Don't hand-roll `for c in $(git log --format=%H); do git checkout "$c"; grep -rc …; done`. Scout already does one checkout per unique commit, optional clean/LFS/submodule repair, and rewrites `--output` after every commit so an interrupted run still leaves usable data. A hand-rolled loop reintroduces all of that, badly.

If scout genuinely can't measure what's asked — say so and stop. The acceptable downstream tools are `jq` over the `--output` JSON and ordinary shell.

## Subcommand → skill map

| User intent | Sub-skill |
|---|---|
| Types by inheritance — `UIView`, `UIViewController`, SwiftUI `View`, `XCTestCase`, own base classes | `scout-types` |
| Files by extension — storyboards, xibs, `.swift`, assets | `scout-files` |
| Literal or regex occurrences in sources — imports, `// TODO:`, `try!`, API usage | `scout-pattern` |
| Lines of code by language and path | `scout-loc` |
| Xcode build settings per target — `SWIFT_VERSION`, deployment target, strict concurrency | `scout-build-settings` |
| Migration progress ("UIKit → SwiftUI", "XCTest → Swift Testing") | `scout-types` + `scout-pattern`, one run each |

Combined questions ("how did the app grow while UIKit shrank?") pull recipes from each sub-skill and merge the JSON with `jq`.

## Shared behaviour, none of it in `--help`

### Output envelope

`--output` is a JSON array with one entry per analyzed commit:

```json
[
  { "commit": "abc1234def5678", "date": "2025-01-15T07:30:00Z", "results": [] }
]
```

`date` is the commit date in UTC ISO 8601. The shape of `results` items differs per subcommand — see the sub-skill. `build-settings` adds a `projects` field alongside `results`.

Without `--output` the numbers only reach the log. **Always pass `--output` when you intend to read the data back.**

The file is rewritten after every commit, not once at the end — a killed run keeps every commit it finished.

### CLI beats config beats default

Positional arguments and flags override the config file. `scout types UIView --config types.json` analyzes `UIView` only, whatever `metrics` the config lists.

### Per-metric commits are config-only

`--commits` applies the same commits to every metric. Different commits per metric need a config file:

```json
{
  "metrics": [
    { "type": "UIView", "commits": ["abc123", "def456"] },
    { "type": "XCTestCase" },
    { "type": "NSObject", "commits": [] }
  ]
}
```

Omitted `commits` means `HEAD`; an empty array skips the metric. `--commits` on the command line overrides all of them.

Every subcommand also accepts a `git` object in its config — `repoPath`, `clean`, `fixLFS`, `initializeSubmodules` — mirroring `--repo-path`, `--git-clean`, `--fix-lfs`, `--initialize-submodules`.

### Commits are analyzed in the order they first appear

Scout doesn't sort them — it walks the metrics and keeps each commit at its first appearance. Pass them oldest-first when building a time series, and pass full hashes from `git log`.

### `--git-clean` deletes your config and output

`git clean -ffdx` removes untracked *and ignored* files under `--repo-path`. A config or output file sitting inside the repository disappears mid-run. Keep both outside: `/tmp`, or `$RUNNER_TEMP` on GitHub Actions.

### The repository is left on the last analyzed commit

Scout checks out commits in the working tree and never restores the original branch — after a historical run the repo sits in detached HEAD. `--fix-lfs` additionally creates local commits (never pushed).

So: run history analysis against a throwaway clone or a dedicated `git worktree`, not the checkout someone is working in. If you do use a live checkout, `git -C <repo> checkout -` afterwards and say so.

### GitHub Actions summary

When `GITHUB_STEP_SUMMARY` is set, each run appends a markdown table of its results to the job summary. Nothing to enable.

## Installation

If `scout` is not on `$PATH`, suggest:

```bash
mise use github:dodobrands/scout
```

Do **not** suggest `swift run scout …` — that's the contributor flow, not the user flow.

Extra requirements by subcommand: `loc` needs `cloc` on `$PATH`; `build-settings` needs `xcodebuild` and is macOS only; `types` resolves base classes from the Xcode SDK on macOS and degrades to source-only analysis on Linux.

## Recipes

### Monthly time series over the whole history

```bash
REPO=~/Developer/myapp
OUT=/tmp/scout
mkdir -p "$OUT"

commits=$(git -C "$REPO" log --reverse --format='%H %cI' \
  | awk '{ month = substr($2, 1, 7); if (month != seen) { print $1; seen = month } }')

scout types UIViewController View \
  --repo-path "$REPO" \
  --commits $commits \
  --output "$OUT/types.json"
```

`awk` keeps the first commit of each calendar month. Feed the same `$commits` to every subcommand so the series line up on identical hashes.

### Flatten a run into CSV for a dashboard

```bash
jq -r '.[] | .date as $d | .results[] | [$d, .typeName, (.types | length)] | @csv' \
  /tmp/scout/types.json
```

`results` items differ per subcommand — swap `.typeName` / `.types | length` for the fields the sub-skill documents.

### One pass, several metrics

Each subcommand is a separate process and a separate checkout loop, so a five-metric report costs five passes over history. Cut it down by putting every metric of one kind into one config file (one `scout` run analyzes all of them per checkout) rather than running the subcommand once per metric.

## Don't

- Don't paste flag lists from memory — read `scout <subcommand> --help`. Subcommands share most flags but not all (`--extensions` is `pattern` only, `--include`/`--exclude` match directory-name suffixes in `loc` and `.xcodeproj` globs in `build-settings`).
- Don't run history analysis in the user's working checkout without saying that it ends on a detached HEAD.
- Don't put `--config` or `--output` inside the analyzed repository when `--git-clean` is on.
- Don't reconstruct a metric with `grep`/`find` over `git checkout` when a subcommand covers it.
- Don't suggest `swift run scout …` to users — that's for contributors to this repo.
