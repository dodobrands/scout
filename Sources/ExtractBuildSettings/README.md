# build-settings

Extracts build settings from Xcode targets across git history. Executes project setup, extracts specific build settings parameters for each target, and uploads metrics to Google Sheets.

## What It Does

For each commit in git history:
1. Checks out the commit and fixes git issues (LFS, submodules)
2. Executes project setup commands sequentially (e.g., `["mise install", "tuist install", "tuist generate --no-open"]`)
3. Discovers all `.xcodeproj` and `.xcworkspace` files in the repository
4. Gets list of targets from each project/workspace using `xcodebuild -list -json`
5. Extracts build settings for each target using `xcodebuild -showBuildSettings -json` (executed in parallel)
6. Extracts specified build settings parameters (e.g., `SWIFT_VERSION`) from all targets
7. Creates JSON with target-value pairs for each parameter: `{"Target1": "5.9", "Target2": "5.10"}`
8. Uploads JSON string to Google Sheets as metric value

## Requirements

- Swift 6.2+
- Access to iOS repository with Xcode project/workspace
- Google Apps Script Web App endpoint URL
- Git repository with commit history
- `xcodebuild` command-line tool
- For Tuist projects: `tuist` command-line tool

## Installation

Build from source:

```bash
swift build
```

Or run directly:

```bash
swift run scout build-settings [arguments]
```

## Usage

### Basic Command

```bash
swift run scout build-settings \
  --repo-path /path/to/ios/repo \
  --config-path extract-build-settings-config.json
```

### Configuration File

Create a JSON configuration file (e.g., `extract-build-settings-config.json`) with the following structure:

```json
{
  "sheetName": "pizza-ios",
  "workingDirectory": "DodoPizza",
  "setupCommands": [
    "mise install",
    "tuist install",
    "tuist generate --no-open"
  ],
  "buildSettingsParameters": ["SWIFT_VERSION"],
  "workspaceName": "DodoPizza",
  "configuration": "Debug"
}
```

**Required fields:**
- `sheetName` — Google Sheets sheet name
- `workingDirectory` — Directory name where setup commands should be executed (relative to repository root)
- `setupCommands` — Array of commands to execute sequentially before analyzing. If any command fails, empty JSON is uploaded for all parameters.
- `buildSettingsParameters` — Array of build settings parameter names to collect
- `workspaceName` — Name of Xcode workspace or project (without extension, e.g., "DodoPizza" for DodoPizza.xcworkspace or DodoPizza.xcodeproj). Used for build settings extraction.
- `configuration` — Build configuration name (e.g., "Debug", "Release")

### Arguments

#### Required

- `--repo-path <path>` — Repository path
- `--config-path <path>` — Path to configuration JSON file (default: `extract-build-settings-config.json`)

#### Optional

- `--secrets-file-path <path>` — Path to secrets file for environment variables (default: `.secrets`)
- `--hash <commit-hash>` — If specified, only this commit will be analyzed (skips commit collection)
- `--branch <branch>` — Git branch to analyze commits from (default: `main`)
- `--interval <seconds>` — Minimum time interval between commits in seconds (default: 86400 = 1 day)
- `--verbose` — Enable verbose logging
- `--dry-run` — Log actions without executing
- `--initialize-submodules` — Initialize submodules (reset and update to correct commits)

### Environment Variables

- `GOOGLE_APPS_SCRIPT_URL` — Google Apps Script Deployment Web App URL (required)

## Configuration

### workingDirectory

Directory name (relative to repository root) where the setup command should be executed.

Example: `"DodoPizza"` will execute setup command in `<repo-path>/DodoPizza/` directory.

### setupCommand

Command to execute before analyzing build settings. Can contain multiple commands separated by `&&`. The command is executed in the `workingDirectory`.

```json
{
  "setupCommand": "mise install && tuist install && tuist generate --no-open"
}
```

Commands are executed sequentially in the project directory.

### workspaceName

Name of Xcode workspace or project file (without extension). The tool will search for `<workspaceName>.xcworkspace` or `<workspaceName>.xcodeproj` in the repository. This is used when extracting build settings to determine which workspace/project to use.

Example: `"DodoPizza"` will search for `DodoPizza.xcworkspace` or `DodoPizza.xcodeproj`.

**Note**: The tool actually discovers all projects/workspaces in the repository, but `workspaceName` is used for build settings extraction commands.

### configuration

Build configuration name to use when extracting build settings (e.g., "Debug", "Release", "Dev").

```json
{
  "configuration": "Debug"
}
```

This is passed to `xcodebuild -showBuildSettings` via the `-configuration` flag.

### buildSettingsParameters

Array of build settings parameter names to collect. Common parameters:

- `SWIFT_VERSION` — Swift language version
- `IPHONEOS_DEPLOYMENT_TARGET` — Minimum iOS deployment target
- `PRODUCT_BUNDLE_IDENTIFIER` — Bundle identifier
- `MARKETING_VERSION` — App version
- `CURRENT_PROJECT_VERSION` — Build number

## How It Works

1. **Commit Collection**: Finds commits to analyze by:
   - Using the first parameter from `buildSettingsParameters` to query Google Sheets for the last processed commit
   - Finding commits on the specified branch after that commit
   - Filtering commits by minimum time interval (default: 1 day)
   - All parameters share the same commit list

2. **Project Setup**: For each commit:
   - Checks out the commit in the repository
   - Fixes git issues (LFS, submodules)
   - Executes setup command in `workingDirectory` (e.g., `mise install && tuist install && tuist generate --no-open`)
   - If setup command fails, the commit is skipped and processing continues with the next commit

3. **Project Discovery**: 
   - Recursively finds all `.xcodeproj` and `.xcworkspace` files in the repository
   - Uses `xcodebuild -list -json` to get list of targets from each project/workspace (executed in parallel)

4. **Build Settings Extraction**:
   - For each target, runs `xcodebuild -showBuildSettings -target <target> -json -configuration <config>` (executed in parallel)
   - Extracts all build settings for each target
   - For each parameter from `buildSettingsParameters`, creates a dictionary: `{"Target1": "value1", "Target2": "value2"}`

5. **Data Upload**: Uploads metrics to Google Sheets with:
   - Date (commit timestamp)
   - Commit hash
   - Metric name (build settings parameter name, e.g., "SWIFT_VERSION")
   - Value (JSON string with target-value pairs, e.g., `{"Menu": "5.9", "Product": "5.10"}`)

## Output

The tool uploads JSON strings to Google Sheets. For each build settings parameter, the value is a JSON string containing target-value pairs:

```json
{
  "Menu": "5.9",
  "Product": "5.10",
  "Cart": "5.9"
}
```

The JSON string is uploaded as the metric value, where:
- Keys are target names
- Values are build settings parameter values for that target

## Examples

### Extract Swift Version

```json
{
  "sheetName": "pizza-ios",
  "workingDirectory": "DodoPizza",
  "setupCommand": "mise install && tuist install && tuist generate --no-open",
  "buildSettingsParameters": ["SWIFT_VERSION"],
  "workspaceName": "DodoPizza"
}
```

### Extract Multiple Parameters

```json
{
  "sheetName": "pizza-ios",
  "workingDirectory": "DodoPizza",
  "setupCommand": "mise install && tuist install && tuist generate --no-open",
  "buildSettingsParameters": [
    "SWIFT_VERSION",
    "IPHONEOS_DEPLOYMENT_TARGET",
    "PRODUCT_BUNDLE_IDENTIFIER"
  ],
  "workspaceName": "DodoPizza",
  "configuration": "Debug"
}
```

## Architecture

The tool is organized into separate classes:

- **`ProjectDiscovery`** — Discovers all Xcode projects/workspaces and extracts targets using `xcodebuild -list -json`
- **`BuildSettingsExtractor`** — Extracts build settings from targets using `xcodebuild -showBuildSettings -json`
- **`ExtractBuildSettings`** — Main command class that orchestrates the workflow

Both `ProjectDiscovery` and `BuildSettingsExtractor` use parallel processing via `concurrentMap` extension for improved performance when processing multiple projects and targets.
