---
name: scout-loc
description: Count lines of code with `scout loc`, a `cloc` wrapper that can replay the count over git history. Trigger when the question is about size rather than count, e.g. "how many lines of Swift do we have?", "how did the codebase grow over two years?", "lines of code per module", "how much Objective-C is left in the legacy module?", "app code versus test code". Takes several languages per metric plus directory include/exclude filters.
---

# `scout loc`

Count lines of code per language and path, at HEAD or across commits. Runs `cloc` under the hood.

Run `scout loc --help` for flags — it is the source of truth. This file covers what the help does not say.

`cloc` must be on `$PATH`: `brew install cloc`, or `apt-get install -y cloc`. Language names are `cloc`'s own spelling — `Swift`, `Objective-C`, `C/C++ Header`. A misspelled language is not an error, it is a zero.

## Config shape

Use a config whenever you want more than one include/exclude combination — the CLI flags describe a single metric.

**CLI and config don't merge here.** Positional languages take the whole CLI branch and the config's metrics are ignored; a config file takes its own branch and `--include` / `--exclude` are dropped. Both failure modes are silent: `scout loc Swift --config loc.json` measures `Swift | .` → `0`, and `scout loc --config loc.json --include Sources` quietly ignores the flag. Pick one side. `--name-template` is the only flag that reaches config metrics.

```json
{
  "metrics": [
    { "languages": ["Swift"], "include": ["Sources"], "exclude": [".build", "Tests", "Vendor"] },
    { "languages": ["Swift"], "include": ["Tests"], "exclude": [".build"], "nameTemplate": "Tests" },
    { "languages": ["Swift", "Objective-C"], "include": ["LegacyModule"], "exclude": [".build"], "commits": ["abc123"] }
  ],
  "git": { "repoPath": "/path/to/repo", "clean": true }
}
```

## `include` is required, and it matches directories by suffix everywhere

This is the one thing to get right.

`include` is not a path and not a glob. Every **directory** under `--repo-path` whose *full path string* ends with one of the strings is measured, at any depth, and the results are summed. It is a string suffix, not a path component: `--include App` also matches `MyApp` and `LegacyApp`, and `--include ttings` matches `Sources/BuildSettings`.

Three consequences, all verified on this repository:

- **Empty `include` measures nothing.** `scout loc Swift` with no `--include` reports `0`, silently. Always pass `--include`.
- **Build artifacts and vendored code count.** `--include Sources` on a checkout with a populated `.build` sweeps in every dependency's `Sources` folder — measured on this repository, that inflated the answer by more than two orders of magnitude. Always exclude `.build`, and whatever else holds a copy of the tree: `Pods`, `DerivedData`, `Carthage`, `node_modules`, extra worktrees.
- **Nested matches double-count.** `Tests/LOCTests/Samples/Sources` matched `Sources` too and its lines were added on top.

`exclude` drops a matched folder when one of its strings appears anywhere in the folder path, case-insensitively — so `.build` and `Pods` work as written, no globs needed.

Sanity-check the first number of a new metric against `cloc --include-lang=Swift <dir>` before building a series on it. An order-of-magnitude gap means the include picked up a tree you didn't mean.

## Metric names

Results are keyed by a rendered name, not by language — which is why two metrics with the same languages need different names. The default template is `%langs% | %include%`, and the placeholders expand to comma-separated lists. Worth knowing because it is how a broken metric announces itself: empty `languages` renders `Unknown`, empty `include` renders `.`, empty `exclude` renders an empty string — a result named `Swift | .` is the silent-zero case below, not a real measurement.

Priority is the usual one: `--name-template` beats `metrics[].nameTemplate` beats the default.

Pick stable names before running history — the name is the join key of the whole time series, and renaming a metric later splits the chart in two.

## Result shape

```json
{
  "commit": "abc1234def5678",
  "date": "2025-01-15T07:30:00Z",
  "results": [
    { "metric": "Swift | Sources", "linesOfCode": 48500 }
  ]
}
```

`linesOfCode` is `cloc`'s code count — comments and blank lines excluded.

## Recipes

### One-off count

```bash
scout loc Swift --include Sources --exclude .build Tests --output /tmp/loc.json
jq -r '.[] | .results[] | "\(.metric)\t\(.linesOfCode)"' /tmp/loc.json
```

### Growth over history, as CSV

```bash
jq -r '.[] | .date as $d | .results[] | [$d, .metric, .linesOfCode] | @csv' /tmp/loc.json
```

### Test-to-code ratio from two metrics

```bash
jq '.[-1].results | (map(select(.metric == "Tests") | .linesOfCode) | add)
    / (map(select(.metric == "Swift | Sources") | .linesOfCode) | add)' /tmp/loc.json
```

### Per-module sizes in one run

Give each module its own metric in the config, with `nameTemplate` set to the module name, and one `scout loc` run covers them all per checkout.

## Don't

- Don't run it without `cloc` installed and report the failure as "no code found".
- Don't run without `--include` — the answer is a silent `0`.
- Don't forget to exclude `.build`, `Pods`, `DerivedData` and other copies of the tree; they are counted otherwise.
- Don't put globs in `include`/`exclude` — matching is suffix and substring. Globs belong to `scout-build-settings`.
- Don't rename a metric mid-series unless you also rewrite the old data.
- Don't compare `linesOfCode` with a file count from `scout-files` as if they measured the same thing.

## See also

- [cloc](https://github.com/AlDanial/cloc) — language names and what counts as code.
- `scout-files` — how many files rather than how many lines.
- `scout` (umbrella) — output envelope, per-metric commits, `--git-clean` footgun, detached HEAD after a run.
