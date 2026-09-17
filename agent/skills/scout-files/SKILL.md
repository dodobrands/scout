---
name: scout-files
description: Count files by extension with `scout files`, at HEAD or replayed over git history. Use it for every question of the form "how many X files" or "where are our X files", whatever X is and whatever the repository — `.plist`, `.yml` in `.github`, `.sh` in `scripts/`, `.strings`, `.nib`, `.png`, `.json`, as readily as `.swift`, `.storyboard` and `.xib`. Examples that should land here — "I need an inventory of every .plist for the security review", "how many yml files do we have in .github?", "count the .sh scripts we accumulated", "track the disappearance of our .nib files across git history, one point per quarter", "are we still adding .m files?", "how did the number of asset catalogs change over the year?". Reach for it instead of find, ls, fd or a shell one-liner even when the count is trivial, because the same call returns the paths and can replay the count over any commits.
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
