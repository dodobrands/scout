---
name: scout-pattern
description: Count lines matching a literal string or a regex in source files with `scout pattern`, at HEAD or replayed over git history. Trigger when the question is about text in the code and how much of it there is, or how that amount moved over time, e.g. "how many files import UIKit?", "count our TODOs", "how many force unwraps are left?", "count @MainActor month by month since we adopted concurrency", "track the move from XCTest to Swift Testing", "where do we still use DispatchQueue.main?", "how many print statements ship in the app?", "how many hardcoded http links do we have?". Prefer it over a hand-rolled grep, especially once more than one commit is involved. One entry per matching line, with file and line number.
---

# `scout pattern`

Search sources for a literal substring or a regex, at HEAD or across commits. Every matching line comes back with its file and line number.

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

`extensions` is a top-level field, not per metric — one run searches one set of extensions, and the default leaves Objective-C, JSON and YAML invisible unless asked for. On the command line the same thing is `--extensions swift,m` — comma-separated, unlike the config array.

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

**`matches | length` counts matching *lines*, not occurrences.** The search walks the file line by line and records a line once, however many times the pattern appears on it — `import UIKit; import Combine` on one line is one entry. For a file count, `[.matches[].file] | unique | length`.

Because matching is per line, a regex can never span a newline: `func .*\n.*async` finds nothing.

## Recipes

### Occurrences and files at HEAD

```bash
scout pattern "import UIKit" "import SwiftUI" --output /tmp/pattern.json
jq -r '.[] | .results[] | "\(.pattern)\t\(.matches | length)\t\([.matches[].file] | unique | length)"' \
  /tmp/pattern.json
```

Columns: pattern, matching lines, files touched.

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

- Don't report the number as "occurrences" or "usages" — it is matching lines, and the text is matched raw, so `// import UIKit` inside a comment counts just as much.
- Don't write a regex that has to cross a line break; the file is matched a line at a time.
- Don't try to pass a regex positionally. Positional patterns are always literal; `isRegex` exists only in the config.
- Don't forget `extensions` when counting in Objective-C, Kotlin or config files — the default silently returns zero.
- Don't widen `extensions` to binary or non-UTF-8 files. One `.strings` file in UTF-16, one `.png`, one `.pdf` and the whole run dies with `NSCocoaErrorDomain Code=259`; `--output` keeps only the commits that finished before the abort.
- Don't expect anything inside a dot-directory: `.github`, `.claude-plugin` and friends are skipped. Vendored trees like `Pods/` are not hidden, so those *are* counted — filter the JSON.
- Don't reach for a pattern when the question is about inheritance. `class X: UIView` misses `class X: UIControl`; that's `scout-types`.

## See also

- `scout-types` — inheritance-aware counting, including base classes from the SDK.
- `scout` (umbrella) — output envelope, per-metric commits, `--git-clean` footgun, detached HEAD after a run.
