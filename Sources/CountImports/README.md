# CountImports

Counts import statement usage across git history. Finds specific import statements in Swift files and uploads metrics to Google Sheets.

## What It Does

Analyzes Swift source files across git commit history to count occurrences of specific import statements. Recursively scans all `.swift` files, extracts import statements, and counts matches for the specified import name.

## Requirements

- Swift 6.2+
- Access to iOS repository
- Google Apps Script Web App endpoint URL
- Git repository with commit history

## Installation

Build from source:

```bash
swift build --product CountImports
```

Or run directly:

```bash
swift run CountImports [arguments]
```

## Usage

### Basic Command

```bash
swift run CountImports \
  --repo-path /path/to/ios/repo \
  --config-path count-imports-config.json
```

### Configuration File

The tool uses a JSON configuration file to specify imports to count. Create a file (e.g., `count-imports-config.json`) with the following structure:

```json
{
  "sheetName": "pizza-ios",
  "imports": ["Testing", "Quick", "Nimble"]
}
```

### Arguments

#### Required

- `--repo-path <path>` — iOS repository path
- `--config-path <path>` — Path to configuration JSON file (default: `count-imports-config.json`)

#### Optional

- `--secrets-file-path <path>` — Path to secrets file for environment variables (default: `.secrets`)
- `--branch <branch>` — Git branch to analyze commits from (default: `main`)
- `--interval <seconds>` — Minimum time interval between commits in seconds (default: 86400 = 1 day)
- `--verbose` — Enable verbose logging
- `--dry-run` — Log actions without executing
- `--initialize-submodules` — Initialize submodules (reset and update to correct commits)

### Environment Variables

- `GOOGLE_APPS_SCRIPT_URL` — Google Apps Script Deployment Web App URL (required)

## How It Works

1. **Configuration Loading**: Loads configuration from JSON file and environment variables
   - Reads `sheetName` and `imports` array from JSON config file
   - Reads `GOOGLE_APPS_SCRIPT_URL` from environment variables or `.secrets` file

2. **Commit Collection**: For each import in the configuration:
   - Querying Google Sheets for the last processed commit for the metric
   - Finding commits on the specified branch after that commit
   - Filtering commits by minimum time interval (default: 1 day)

3. **Import Analysis**: For each commit:
   - Checks out the commit in the repository
   - Finds all `.swift` files recursively
   - Parses each file to extract import statements
   - Counts exact matches for the current import name

4. **Data Upload**: Uploads metrics to Google Sheets with:
   - Date (commit timestamp)
   - Commit hash
   - Metric name (the import name, e.g., "Testing")
   - Value (import count)

## Examples

### Basic Usage

Create `count-imports-config.json`:
```json
{
  "sheetName": "pizza-ios",
  "imports": ["Testing"]
}
```

Run:
```bash
export GOOGLE_APPS_SCRIPT_URL=https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
swift run CountImports \
  --repo-path ~/Developer/dodo-mobile-ios \
  --config-path count-imports-config.json
```

### Multiple Imports

Create `count-imports-config.json`:
```json
{
  "sheetName": "pizza-ios",
  "imports": ["Testing", "Quick", "Nimble", "NSpry"]
}
```

Run:
```bash
export GOOGLE_APPS_SCRIPT_URL=https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
swift run CountImports \
  --repo-path ~/Developer/dodo-mobile-ios \
  --config-path count-imports-config.json
```

### Custom Branch and Interval

```bash
export GOOGLE_APPS_SCRIPT_URL=https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
swift run CountImports \
  --repo-path ~/Developer/dodo-mobile-ios \
  --config-path count-imports-config.json \
  --branch develop \
  --interval 3600
```

### Dry-Run Mode

```bash
export GOOGLE_APPS_SCRIPT_URL=https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
swift run CountImports \
  --repo-path ~/Developer/dodo-mobile-ios \
  --config-path count-imports-config.json \
  --dry-run
```

## Import Matching

CountImports extracts the module name from import statements and performs exact matching:

- **Matches**: `import Testing` (extracts "Testing")
- **Matches**: `@testable import Testing` (extracts "Testing")
- **Matches**: `import Testing.Foundation` (extracts "Testing" from submodule import)
- **Matches**: `@testable import Testing.Foundation` (extracts "Testing" from submodule import)

Note: When searching for "Testing", all of the above will be counted because the tool extracts only the base module name (the part before the dot).

The tool counts each occurrence of the exact import statement across all Swift files in the repository.

## Output

The tool logs progress and results for each import:

```
Processing import: Testing
Will analyze 5 commits for import 'Testing'
Found 42 imports 'Testing' at 2024-01-15 10:30:00 +0000, abc123def
Would upload: sheetName="pizza-ios", metric="Testing", value=42
Found 45 imports 'Testing' at 2024-01-16 10:30:00 +0000, def456ghi
Would upload: sheetName="pizza-ios", metric="Testing", value=45
...
Summary for 'Testing': 5 upload(s) performed
Processing import: Quick
Will analyze 3 commits for import 'Quick'
...
Summary for 'Quick': 3 upload(s) performed
Total summary: 8 upload(s) performed
```

## Common Use Cases

Track usage of specific frameworks or libraries over time to understand adoption patterns and plan migrations. For example, monitor the transition from Quick/Nimble to Swift Testing by counting imports for each framework.

## Error Handling

Common errors and solutions:

- **"Directory does not exist"**: Check that `--repo-path` points to a valid directory.
- **"Failed to create enumerator"**: File system access issue. Check permissions.
- **"Invalid URL"**: Check that `--endpoint` is a valid URL.

## Dry-Run Mode

When `--dry-run` is enabled:
- Read operations (commit checkout, import parsing) run normally
- Write operations (Google Sheets uploads) are logged but not executed
- All operations that would run are logged
- Summary shows how many uploads would have been performed

## See Also

- [AGENTS.md](../../AGENTS.md) — General project documentation
- [CodeReader](../../Sources/CodeReader/README.md) — Code parsing library documentation