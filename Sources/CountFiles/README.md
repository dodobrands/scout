# CountFiles

Counts files by type across git history. Finds files with specified extensions and uploads file counts to Google Sheets.

## What It Does

Analyzes repository structure across git commit history to count files with specific file extensions. Recursively scans the repository, filters files by extension, and uploads file counts to Google Sheets.

## Requirements

- Swift 6.2+
- Access to repository
- Google Apps Script Web App endpoint URL
- Git repository with commit history

## Installation

Build from source:

```bash
swift build --product CountFiles
```

Or run directly:

```bash
swift run CountFiles [arguments]
```

## Usage

### Basic Command

```bash
swift run CountFiles \
  --repo-path /path/to/repo \
  --filetype storyboard \
  --sheet-name pizza-ios \
  --endpoint https://script.google.com/macros/s/.../exec
```

### Arguments

#### Required

- `--repo-path <path>` — Repository path
- `--filetype <extension>` — File extension to count (without dot, e.g., `storyboard`, `xib`, `swift`)
- `--sheet-name <name>` — Google Sheets sheet name to upload data to
- `--endpoint <url>` — Google Apps Script Deployment Web App URL

#### Optional

- `--branch <branch>` — Git branch to analyze commits from (default: `main`)
- `--interval <seconds>` — Minimum time interval between commits in seconds (default: 86400 = 1 day)
- `--verbose` — Enable verbose logging
- `--dry-run` — Log actions without executing
- `--initialize-submodules` — Initialize submodules (reset and update to correct commits)

## How It Works

1. **Commit Collection**: Finds commits to analyze by:
   - Querying Google Sheets for the last processed commit for the metric
   - Finding commits on the specified branch after that commit
   - Filtering commits by minimum time interval (default: 1 day)

2. **File Analysis**: For each commit:
   - Checks out the commit in the repository
   - Recursively finds all files with the specified extension
   - Counts matching files

3. **Data Upload**: Uploads metrics to Google Sheets with:
   - Date (commit timestamp)
   - Commit hash
   - Metric name (the filetype, e.g., "storyboard")
   - Value (file count)

## Examples

### Basic Usage

```bash
swift run CountFiles \
  --repo-path ~/Developer/dodo-mobile-ios \
  --filetype storyboard \
  --sheet-name pizza-ios \
  --endpoint https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
```

### Custom Branch and Interval

```bash
swift run CountFiles \
  --repo-path ~/Developer/dodo-mobile-ios \
  --filetype storyboard \
  --sheet-name pizza-ios \
  --endpoint https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec \
  --branch develop \
  --interval 3600
```

### Dry-Run Mode

```bash
swift run CountFiles \
  --repo-path ~/Developer/dodo-mobile-ios \
  --filetype storyboard \
  --sheet-name pizza-ios \
  --endpoint https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec \
  --dry-run
```

## File Extension Matching

CountFiles matches file extensions exactly (case-sensitive):

- `--filetype storyboard` matches: `Main.storyboard`, `Settings.storyboard`
- `--filetype xib` matches: `CustomView.xib`, `AnotherView.xib`
- `--filetype swift` matches: `ViewController.swift`, `Model.swift`

The tool scans all files recursively, including those in subdirectories, but excludes hidden files.

## Common Use Cases

Track usage of specific file types over time to understand codebase composition and plan refactoring efforts. For example, monitor the transition from Storyboards/XIBs to SwiftUI by counting files of each type.

## Output

The tool logs progress and results:

```
Will analyze 5 commits
Found 25 files of type 'storyboard' at 2024-01-15 10:30:00 +0000, abc123def
Would upload: sheetName="pizza-ios", metric="storyboard", value=25
Found 24 files of type 'storyboard' at 2024-01-16 10:30:00 +0000, def456ghi
Would upload: sheetName="pizza-ios", metric="storyboard", value=24
...
Summary: 5 upload(s) performed
```

## Error Handling

Common errors and solutions:

- **"Directory does not exist"**: Check that `--repo-path` points to a valid directory.
- **"Failed to create enumerator"**: File system access issue. Check permissions.
- **"Invalid URL"**: Check that `--endpoint` is a valid URL.

## Dry-Run Mode

When `--dry-run` is enabled:
- Read operations (commit checkout, file scanning) run normally
- Write operations (Google Sheets uploads) are logged but not executed
- All operations that would run are logged
- Summary shows how many uploads would have been performed

## See Also

- [AGENTS.md](../../AGENTS.md) — General project documentation