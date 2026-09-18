---
name: scout-files
description: Count files by extension with `scout files` and replay that count over git history. Use it whenever the answer is a per-extension inventory or how one moved over time — "сколько сторибордов было год назад и сколько сейчас", "how many yml files were in .github a year ago versus now", "how did the markdown file count change per quarter", "file counts for swift, storyboard and xib at these three commits", "a burn-down of our graphql files across the last 12 months as data I can chart", "export swift/storyboard/xib counts as json every month for Grafana", "an inventory of every .sh file with its path", "track the disappearance of our .nib files, one point per quarter". Any extension counts, not only iOS ones. A bare count in the current checkout is a job for find; this skill earns its place when the question spans commits, needs the paths, or has to produce data that lines up with the other scout metrics. It counts files, never their size on disk.
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

**Paths are absolute**, not relative to the repository root — `/Users/you/Developer/app/Sources/App.swift`. `scout types` and `scout pattern` return relative paths; `files` is the odd one out, so strip the prefix yourself before joining the data with theirs.

The count is `files | length`.

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
REPO=~/Developer/myapp
jq -r --arg repo "$REPO/" '.[-1].results[] | select(.filetype == "xib") | .files[] | sub($repo; "")' \
  /tmp/files.json | cut -d/ -f1-2 | sort | uniq -c | sort -rn
```

The `sub` strips the absolute prefix; without it every path buckets under `/Users`.

### Two extensions as one number

```bash
jq '.[-1].results | map(select(.filetype == "storyboard" or .filetype == "xib") | .files | length) | add' \
  /tmp/files.json
```

## Don't

- Don't pass `.swift` with the leading dot — nothing matches and the zero looks real.
- Don't use it for lines of code. A file count says nothing about size; that's `scout-loc`.
- Don't expect the file list to be filtered by path. There is no include/exclude here at all, so `Pods/`, `Carthage/`, `DerivedData/` and vendored sources are counted — filter the JSON with `jq`.
- Don't look for anything inside a dot-directory: hidden files and folders are skipped, so "count our CI workflows in `.github`" comes back zero.
- Don't feed these paths to something expecting repo-relative ones without stripping the prefix first.

## See also

- `scout-loc` — size rather than count, with include/exclude paths.
- `scout` (umbrella) — output envelope, per-metric commits, `--git-clean` footgun, detached HEAD after a run.
