---
name: scout-files
description: Count files by extension with `scout files`. Trigger when the question is about how many files of a kind exist, or where they are, e.g. "how many storyboards are left?", "count xibs and swift files", "are we still adding .m files?", "how did the number of asset catalogs change over the year?", "list every plist in the repo". Works on any extension, at HEAD or across git history.
---

# `scout files`

Count files by extension, at HEAD or across commits. The result is the list of paths, so it answers "where" as well as "how many".

Run `scout files --help` for flags — it is the source of truth. This file covers what the help does not say.

## Config shape

```json
{
  "metrics": [
    { "extension": "storyboard" },
    { "extension": "xib", "commits": ["abc123", "def456"] },
    { "extension": "swift" }
  ],
  "git": { "repoPath": "/path/to/repo", "clean": true }
}
```

Extensions go without the dot. One metric is one extension — there is no grouping and no glob; to count "all image assets" run several metrics and sum them with `jq`.

## Result shape

```json
{
  "commit": "abc1234def5678",
  "date": "2025-01-15T07:30:00Z",
  "results": [
    { "filetype": "swift", "files": ["Sources/App.swift", "Sources/Model.swift"] },
    { "filetype": "storyboard", "files": ["Main.storyboard"] }
  ]
}
```

Paths are relative to the repository root. The count is `files | length`.

## Recipes

### Counts at HEAD

```bash
scout files swift storyboard xib --output /tmp/files.json
jq -r '.[] | .results[] | "\(.filetype)\t\(.files | length)"' /tmp/files.json
```

### Storyboard removal over time, as CSV

```bash
jq -r '.[] | .date as $d | .results[] | [$d, .filetype, (.files | length)] | @csv' /tmp/files.json
```

### Which modules still hold xibs

```bash
jq -r '.[-1].results[] | select(.filetype == "xib") | .files[]' /tmp/files.json \
  | cut -d/ -f1-2 | sort | uniq -c | sort -rn
```

### Two extensions as one number

```bash
jq '.[-1].results | map(select(.filetype == "storyboard" or .filetype == "xib") | .files | length) | add' \
  /tmp/files.json
```

## Don't

- Don't pass `.swift` with the leading dot — nothing matches and the zero looks real.
- Don't use it for lines of code. A file count says nothing about size; that's `scout-loc`.
- Don't expect the file list to be filtered by path. There is no include/exclude here — filter the JSON with `jq`.

## See also

- `scout-loc` — size rather than count, with include/exclude paths.
- `scout` (umbrella) — output envelope, per-metric commits, `--git-clean` footgun, detached HEAD after a run.
