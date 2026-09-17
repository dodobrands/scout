---
name: scout-build-settings
description: Extract Xcode build settings per target with `scout build-settings`. Trigger when the question is about project configuration rather than source code, e.g. "which Swift version do our targets build with?", "what is our minimum iOS deployment target?", "which modules still have strict concurrency off?", "when did we move to Swift 6?", "show SWIFT_VERSION per target across the last year". Discovers `.xcodeproj` files by glob and can run setup commands first, so Tuist and XcodeGen projects work too. macOS only.
---

# `scout build-settings`

Read build settings from every discovered `.xcodeproj`, per target, at HEAD or across commits. Shells out to `xcodebuild`, so it is **macOS only**.

Run `scout build-settings --help` for flags — it is the source of truth. This file covers what the help does not say.

## Project discovery is required

Nothing runs without `--include` (CLI) or `projects.include` (config). Patterns are globs — `*` within a segment, `**` across segments, `?` for one character. `**/*.xcodeproj` is the usual start.

**Put the settings you want *before* `--include`.** `--include` and `--exclude` consume every following word until the next flag, so `scout build-settings --include "**/*.xcodeproj" SWIFT_VERSION` swallows `SWIFT_VERSION` as a glob and runs zero metrics — logging `Will analyze 0 commit(s) for 0 metric(s)`, exiting 0, writing no output. Same trap with `--commits`.

**`**/*.xcodeproj` sweeps far more than your app.** On this repository it discovered 37 projects — SPM checkouts under `.build`, test fixtures, worktree copies — and mixed their Swift versions into the answer. Exclude `.build`, `Pods`, `DerivedData`, `Carthage` and any vendored tree, then read the `projects` array and confirm it lists what you expected before trusting a single number.

## Config shape

```json
{
  "projects": {
    "include": ["MyApp/**/*.xcodeproj"],
    "exclude": ["Pods/**"],
    "continueOnMissing": true
  },
  "configuration": "Debug",
  "metrics": [
    { "setting": "SWIFT_VERSION" },
    { "setting": "IPHONEOS_DEPLOYMENT_TARGET", "commits": ["abc123"] }
  ],
  "setupCommands": [
    { "command": "mise install", "optional": true },
    { "command": "tuist install", "workingDirectory": "MyApp", "optional": true },
    { "command": "tuist generate --no-open", "workingDirectory": "MyApp", "optional": true }
  ]
}
```

`configuration` defaults to `Debug`; settings can differ per configuration, so say which one a number came from.

`setupCommands` run at every commit before discovery — this is how generated projects get generated. `workingDirectory` is relative to the repository root. A command with shell operators (`|`, `&&`) runs through `/bin/sh`; a plain one runs directly. `optional: true` lets the run continue when the command fails, which is what makes ancient commits survivable.

## Generated projects: the danger is a silent flatline, not a dead run

On old commits the generator or its dependencies are often gone, and no `.xcodeproj` appears. What happens then is worth knowing exactly, because it is not what `--help` says: any failure at a commit — no projects found, `xcodebuild` blowing up, a setup command dying — is caught, logged as a `warning ... Skipping commit due to error`, and the commit is emitted with empty targets. The run continues and exits 0 **with or without** `--continue-on-missing-project`. (The help claims the default is to fail; the code disagrees. Don't build a CI gate on the exit code.)

So the hazard is not losing the run, it is quietly charting zeros. An empty-target result is indistinguishable from "the setting is unset everywhere":

```json
{ "commit": "e18beffdf4", "date": "2024-03-10T11:17:36Z",
  "results": [ { "setting": "SWIFT_VERSION", "targets": {} } ] }
```

Check `targets == {}` before plotting, and read the stderr warnings — that is the only place the reason shows up. Keep `optional: true` on setup commands anyway, so a dead generator doesn't take the rest of the commit's work with it.

## Result shape

```json
{
  "commit": "abc1234def5678",
  "date": "2025-01-15T07:30:00Z",
  "projects": [
    { "path": "/Users/you/Developer/myapp/MyApp/MyApp.xcodeproj", "targets": ["MyApp", "MyAppTests"] }
  ],
  "results": [
    { "setting": "SWIFT_VERSION", "targets": { "MyApp": "5.0", "MyAppTests": "5.0" } }
  ]
}
```

Three things are specific to this subcommand:

- The extra `projects` field says which project declares which target. Target names alone don't: `MyAppTests` belongs to `MyApp`, but `MenuSearch` next to `Menu` is a different project. Its `path` is **absolute**, whatever the SDK doc-comment claims.
- **`results[].targets` is keyed by target name alone, across all discovered projects — same name, last one wins.** On this repository `**/*.xcodeproj` found ten separate projects each declaring a `TestApp` target, and `targets` came back with a single `TestApp` entry. So grouping by `projects[].path` only works when target names are unique: check `projects` for repeated names first, and if they repeat, narrow `--include` to one project at a time instead of reporting per module.
- A target that doesn't define the requested setting gets `null`, not a missing key. `null` and `""` are different answers — treat `null` as "inherits or unset".

## Recipes

### Setting per target at HEAD

```bash
scout build-settings SWIFT_VERSION --include "**/*.xcodeproj" --exclude ".build/**" --output /tmp/bs.json
jq -r '.[-1].results[] | .setting as $s | .targets | to_entries[] | "\($s)\t\(.key)\t\(.value // "—")"' /tmp/bs.json
```

### Distribution of values across targets

```bash
jq -r '.[-1].results[] | select(.setting == "SWIFT_VERSION") | .targets | to_entries
       | group_by(.value)[] | "\(.[0].value // "null")\t\(length)"' /tmp/bs.json
```

### Targets still missing a setting

```bash
jq -r '.[-1].results[] | select(.setting == "SWIFT_STRICT_CONCURRENCY")
       | .targets | to_entries[] | select(.value == null) | .key' /tmp/bs.json
```

### Per module rather than per target

Only sound when no target name repeats across projects — see the result shape above.

```bash
jq -r '.[-1] as $o | $o.projects[] | .path as $p | .targets[] as $t
       | $o.results[] | select(.setting == "SWIFT_VERSION")
       | [$p, $t, (.targets[$t] // "—")] | @tsv' /tmp/bs.json
```

### When a value changed

```bash
jq -r '.[] | .date as $d | .results[] | select(.setting == "SWIFT_VERSION")
       | [$d, (.targets | to_entries | map(.value) | unique | join(","))] | @tsv' /tmp/bs.json
```

## Don't

- Don't run it on Linux — the subcommand doesn't exist there.
- Don't write the settings after `--include` / `--exclude` / `--commits`; they get eaten and the run does nothing, loudly enough to miss.
- Don't treat exit 0 as "every commit measured" — failed commits come back with empty targets and a warning on stderr.
- Don't infer module ownership from target name prefixes. Use `projects` — and check it for duplicate target names before reporting per module.
- Don't trust `**/*.xcodeproj` without an exclude; dependency and fixture projects land in the same answer.
- Don't read `null` as "off" — it means the target doesn't set it.
- Don't compare numbers taken under different `configuration` values.

## See also

- `scout` (umbrella) — output envelope, per-metric commits, `--git-clean` footgun, detached HEAD after a run.
