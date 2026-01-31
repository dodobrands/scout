# build-settings

Extract build settings from Xcode projects.

## Usage

```bash
scout build-settings \
  --repo-path /path/to/repo \
  --commits "abc123,def456"
```

## Arguments

### Required

- `--repo-path, -r <path>` — Path to repository

### Optional

- `--config <path>` — Path to configuration JSON file
- `--commits, -c <hashes>` — Comma-separated list of commit hashes to analyze (default: HEAD)
- `--output, -o <path>` — Path to save JSON results
- `--verbose, -v` — Enable verbose logging
- `--initialize-submodules, -I` — Initialize submodules (reset and update to correct commits)

## Configuration (Optional)

Configuration file is optional. Pass it via `--config` flag:

```bash
scout build-settings --repo-path /path/to/repo --config build-settings-config.json
```

### JSON Format

```json
{
  "setupCommands": [
    { "command": "mise install" },
    { "command": "tuist install", "workingDirectory": "App" },
    { "command": "tuist generate --no-open", "workingDirectory": "App" }
  ],
  "buildSettingsParameters": ["SWIFT_VERSION", "IPHONEOS_DEPLOYMENT_TARGET"],
  "workspaceName": "MyApp",
  "configuration": "Debug"
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `setupCommands` | `[SetupCommand]` | Commands to execute before analyzing |
| `setupCommands[].command` | `String` | Shell command to execute |
| `setupCommands[].workingDirectory` | `String?` | Directory relative to repo root (optional) |
| `buildSettingsParameters` | `[String]` | Build settings to extract |
| `workspaceName` | `String` | Xcode workspace/project name (without extension) |
| `configuration` | `String` | Build configuration (Debug, Release, etc.) |

## Requirements

- `xcodebuild` command-line tool
- For Tuist projects: `tuist` CLI
