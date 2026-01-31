# CountLOC

Counts lines of code (LOC) across git history using `cloc`. Analyzes code in specified languages and directories, filters by include/exclude patterns, and uploads metrics to Google Sheets.

## What It Does

Uses the `cloc` tool to count lines of code in specified programming languages across git commit history. Supports filtering directories by include/exclude patterns and uploads LOC metrics to Google Sheets.

## Requirements

- Swift 6.2+
- `cloc` tool installed (see [Installation](#cloc-installation))
- Access to repository
- Google Apps Script Web App endpoint URL
- Git repository with commit history

## Installation

### Build from Source

```bash
swift build --product CountLOC
```

Or run directly:

```bash
swift run CountLOC [arguments]
```

### cloc Installation

CountLOC requires `cloc` to be installed. Install it using one of the following methods:

**macOS:**
```bash
brew install cloc
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get update && sudo apt-get install -y cloc
```

**Linux (Fedora/RHEL):**
```bash
sudo dnf install cloc
```

**Or download from:** https://github.com/AlDanial/cloc/releases

If `cloc` is not installed, CountLOC shows a helpful error message with installation instructions.

## Usage

### Basic Command

```bash
swift run CountLOC \
  --repo-path /path/to/repo \
  --languages "Java,Kotlin" \
  --include "src/main" \
  --exclude "test" \
  --sheet-name pizza-android \
  --endpoint https://script.google.com/macros/s/.../exec
```

### Arguments

#### Required

- `--repo-path <path>` — Repository path
- `--languages <langs>` — Programming languages to count, comma-separated (e.g., "Java,Kotlin", "Swift", "Objective-C")
- `--include <paths>` — Only folders with this value in their path will be scanned, comma-separated (e.g., "src/main", "app/src/main")
- `--exclude <paths>` — Folders with this value will be excluded from 'include', comma-separated (e.g., "test", "tests")
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

2. **Directory Filtering**: For each commit:
   - Checks out the commit in the repository
   - Finds directories matching `--include` patterns
   - Excludes directories matching `--exclude` patterns
   - Processes each matching directory

3. **LOC Counting**: For each matching directory:
   - Runs `cloc` for each specified language
   - Sums LOC counts across all languages and directories
   - Uses the total LOC count as the metric value

4. **Data Upload**: Uploads metrics to Google Sheets with:
   - Date (commit timestamp)
   - Commit hash
   - Metric name (format: "LOC [languages] [include]")
   - Value (total LOC count)

## Examples

### Android Repository

```bash
swift run CountLOC \
  --repo-path ~/Developer/dodo-mobile-android \
  --languages "Java,Kotlin" \
  --include "src/main" \
  --exclude "test" \
  --sheet-name pizza-android \
  --endpoint https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
```

### iOS Repository

```bash
swift run CountLOC \
  --repo-path ~/Developer/dodo-mobile-ios \
  --languages "Swift" \
  --include "Sources" \
  --exclude "Tests" \
  --sheet-name pizza-ios \
  --endpoint https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
```

### Multiple Include Patterns

```bash
swift run CountLOC \
  --repo-path ~/Developer/dodo-mobile-android \
  --languages "Java,Kotlin" \
  --include "app/src/main,domain/src/main" \
  --exclude "test,tests" \
  --sheet-name pizza-android \
  --endpoint https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
```

### Custom Branch and Interval

```bash
swift run CountLOC \
  --repo-path ~/Developer/dodo-mobile-android \
  --languages "Java,Kotlin" \
  --include "src/main" \
  --exclude "test" \
  --sheet-name pizza-android \
  --endpoint https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec \
  --branch develop \
  --interval 3600
```

### Dry-Run Mode

```bash
swift run CountLOC \
  --repo-path ~/Developer/dodo-mobile-android \
  --languages "Java,Kotlin" \
  --include "src/main" \
  --exclude "test" \
  --sheet-name pizza-android \
  --endpoint https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec \
  --dry-run
```

## Directory Filtering Logic

1. **Include**: Directories whose path ends with any of the `--include` values are included
2. **Exclude**: Directories whose path contains (case-insensitive) any of the `--exclude` values are excluded
3. **Processing**: Only directories that pass both filters are analyzed

Example:
- `--include "src/main"` matches: `app/src/main`, `domain/src/main`, `lib/src/main`
- `--exclude "test"` excludes: `app/src/test`, `domain/src/test`, `app/src/main/test`

## Supported Languages

CountLOC supports all languages supported by `cloc`. Common examples:

- `Swift`
- `Java`
- `Kotlin`
- `Objective-C`
- `C`
- `C++`
- `JavaScript`
- `TypeScript`
- `Python`
- `Ruby`
- `Go`
- `Rust`

See `cloc --help` for the full list of supported languages.

## Output

The tool logs progress and results:

```
Will analyze 5 commits
Found 125000 lines of '["Java", "Kotlin"]' code at 2024-01-15 10:30:00 +0000, abc123def
Would upload: sheetName="pizza-android", metric="LOC [\"Java\", \"Kotlin\"] [\"src/main\"]", value=125000
Found 125500 lines of '["Java", "Kotlin"]' code at 2024-01-16 10:30:00 +0000, def456ghi
Would upload: sheetName="pizza-android", metric="LOC [\"Java\", \"Kotlin\"] [\"src/main\"]", value=125500
...
Summary: 5 upload(s) performed
```

## Error Handling

Common errors and solutions:

- **"cloc is not installed"**: Install `cloc` using one of the methods described in [cloc Installation](#cloc-installation).
- **"Invalid URL"**: Check that `--endpoint` is a valid URL.
- **No directories found**: Check that `--include` patterns match directories in your repository structure.

## Dry-Run Mode

When `--dry-run` is enabled:
- Read operations (commit checkout, LOC counting) run normally
- Write operations (Google Sheets uploads) are logged but not executed
- All operations that would run are logged
- Summary shows how many uploads would have been performed

## See Also

- [AGENTS.md](../../AGENTS.md) — General project documentation
- [cloc documentation](https://github.com/AlDanial/cloc) — Official cloc tool documentation