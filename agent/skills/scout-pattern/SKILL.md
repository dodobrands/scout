---
name: scout-pattern
description: Find literal or regex occurrences in source files with `scout pattern`. Trigger when the question is about text in the code and how much of it there is, e.g. "how many files import UIKit?", "count our TODOs", "how many force unwraps are left?", "track the move from XCTest to Swift Testing", "where do we still use DispatchQueue.main?", "how many print statements ship in the app?". One occurrence per match, with file and line, at HEAD or across git history.
---

# `scout pattern`

Search sources for a literal substring or a regex, at HEAD or across commits. Every match comes back with its file and line.

Run `scout pattern --help` for flags — it is the source of truth. This file covers what the help does not say.

## Config shape

```json
{
  "metrics": [
    { "pattern": "import Testing" },
    { "pattern": "// TODO:", "commits": ["abc123", "def456"] },
    { "pattern": "DispatchQueue\\.(main|global)", "isRegex": true }
  ],
  "extensions": ["swift", "m"],
  "git": { "repoPath": "/path/to/repo", "clean": true }
}
```

`extensions` is a top-level field, not per metric — one run searches one set of extensions. It defaults to `["swift"]`, so Objective-C, JSON and YAML are invisible unless asked for. On the command line the same thing is `--extensions swift,m` (comma-separated, unlike the config array).

`isRegex` switches a metric from substring matching to `NSRegularExpression`. It is config-only — there is no CLI flag, so a regex metric needs a config file. In JSON every backslash doubles: `"\\btry!\\s"`, `"@available\\(.*deprecated"`.

## Result shape

```json
{
  "commit": "abc1234def5678",
  "date": "2025-01-15T07:30:00Z",
  "results": [
    {
      "pattern": "import UIKit",
      "matches": [
        { "file": "Sources/App.swift", "line": 1 },
        { "file": "Sources/View.swift", "line": 1 }
      ]
    }
  ]
}
```

`matches | length` counts occurrences, not files — two matches in one file are two entries. For a file count, `[.matches[].file] | unique | length`.

## Recipes

### Occurrences and files at HEAD

```bash
scout pattern "import UIKit" "import SwiftUI" --output /tmp/pattern.json
jq -r '.[] | .results[] | "\(.pattern)\t\(.matches | length)\t\([.matches[].file] | unique | length)"' \
  /tmp/pattern.json
```

### Regex metrics need a config

```bash
cat > /tmp/pattern.json <<'JSON'
{ "metrics": [ { "pattern": "\\btry!\\s", "isRegex": true }, { "pattern": "\\w+!", "isRegex": true } ] }
JSON
scout pattern --config /tmp/pattern.json --output /tmp/unsafe.json
```

### Test-framework migration as a time series

```bash
jq -r '.[] | .date as $d | .results[] | [$d, .pattern, (.matches | length)] | @csv' /tmp/pattern.json
```

### Worst files for one pattern

```bash
jq -r '.[-1].results[] | select(.pattern == "// TODO:") | .matches[].file' /tmp/pattern.json \
  | sort | uniq -c | sort -rn | head -20
```

## Don't

- Don't expect comments or strings to be excluded — matching is textual, so `// import UIKit` counts. Word it as "occurrences", not "usages".
- Don't try to pass a regex positionally. Positional patterns are always literal; `isRegex` exists only in the config.
- Don't forget `extensions` when counting in Objective-C, Kotlin or config files — the default `swift` silently returns zero.
- Don't reach for a pattern when the question is about inheritance. `class X: UIView` misses `class X: UIControl`; that's `scout-types`.

## See also

- `scout-types` — inheritance-aware counting, including base classes from the SDK.
- `scout` (umbrella) — output envelope, per-metric commits, `--git-clean` footgun, detached HEAD after a run.
