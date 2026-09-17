---
name: scout-build-settings
description: Extract Xcode build settings per target with `scout build-settings`. Trigger when the question is about project configuration rather than source code, e.g. "which Swift version do our targets build with?", "what is our minimum iOS deployment target?", "which modules still have strict concurrency off?", "when did we move to Swift 6?", "show SWIFT_VERSION per target across the last year". Discovers `.xcodeproj` files by glob and can run setup commands first, so Tuist and XcodeGen projects work too. macOS only.
---

# `scout build-settings`

Read build settings from every discovered `.xcodeproj`, per target, at HEAD or across commits. Shells out to `xcodebuild`, so it is **macOS only**.

Run `scout build-settings --help` for flags — it is the source of truth. This file covers what the help does not say.

## Project discovery is required

Nothing runs without `--include` (CLI) or `projects.include` (config). Patterns are globs — `*` within a segment, `**` across segments, `?` for one character — matched against paths relative to the repository root. `**/*.xcodeproj` is the usual start; `Pods/**` is the usual exclude.

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

## Generated projects: mark them optional and continue on missing

On old commits the generator or its dependencies are often gone, and no `.xcodeproj` appears. By default that fails the whole run. `--continue-on-missing-project` (or `projects.continueOnMissing`) records an empty result for that commit and moves on. Combine it with `optional: true` on every setup command when sweeping deep history.

An empty-target result is indistinguishable from "the setting is unset everywhere", so check for it when a series suddenly flatlines:

```json
{ "commit": "e18beffdf4", "date": "2024-03-10T11:17:36Z",
  "results": [ { "setting": "SWIFT_VERSION", "targets": {} } ] }
```

## Result shape

```json
{
  "commit": "abc1234def5678",
  "date": "2025-01-15T07:30:00Z",
  "projects": [
    { "path": "MyApp/MyApp.xcodeproj", "targets": ["MyApp", "MyAppTests"] }
  ],
  "results": [
    { "setting": "SWIFT_VERSION", "targets": { "MyApp": "5.0", "MyAppTests": "5.0" } }
  ]
}
```

Two things are specific to this subcommand:

- The extra `projects` field says which project declares which target. Target names alone don't: `MyAppTests` belongs to `MyApp`, but `MenuSearch` next to `Menu` is a different project. **Group by `projects[].path` when reporting per module.**
- A target that doesn't define the requested setting gets `null`, not a missing key. `null` and `""` are different answers — treat `null` as "inherits or unset".

## Recipes

### Setting per target at HEAD

```bash
scout build-settings --include "**/*.xcodeproj" SWIFT_VERSION --output /tmp/bs.json
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
- Don't sweep history without `--continue-on-missing-project` and `optional: true` setup commands; one unbuildable commit kills the whole run.
- Don't infer module ownership from target name prefixes. Use `projects`.
- Don't read `null` as "off" — it means the target doesn't set it.
- Don't compare numbers taken under different `configuration` values.

## See also

- `scout` (umbrella) — output envelope, per-metric commits, `--git-clean` footgun, detached HEAD after a run.
