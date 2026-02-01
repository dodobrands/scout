# build-settings

Extract build settings from Xcode projects.

## Usage

```bash
# Use config file (required for setup commands and parameters)
scout build-settings --config build-settings-config.json

# Analyze specific commits
scout build-settings --config build-settings-config.json --commits abc123 def456
```

## Arguments

### Optional

- `--repo-path, -r <path>` — Path to repository (default: current directory)
- `--config <path>` — Path to configuration JSON file
- `--commits, -c <hashes>` — Commit hashes to analyze (default: HEAD)
- `--output, -o <path>` — Path to save JSON results
- `--verbose, -v` — Enable verbose logging
- `--initialize-submodules, -I` — Initialize submodules (reset and update to correct commits)

## Configuration

Build settings tool requires a config file to specify setup commands and parameters.

```bash
scout build-settings --config build-settings-config.json
```

### JSON Format

**Minimal (no setup commands):**

```json
{
  "workspaceName": "MyApp",
  "configuration": "Debug",
  "buildSettingsParameters": ["SWIFT_VERSION", "IPHONEOS_DEPLOYMENT_TARGET"]
}
```

**With setup commands (e.g., for generated projects):**

```json
{
  "workspaceName": "MyApp",
  "configuration": "Debug",
  "buildSettingsParameters": ["SWIFT_VERSION", "IPHONEOS_DEPLOYMENT_TARGET"],
  "setupCommands": [
    { "command": "mise install", "optional": true },
    { "command": "tuist install", "workingDirectory": "App" },
    { "command": "tuist generate --no-open", "workingDirectory": "App" }
  ]
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `workspaceName` | `String` | Xcode workspace/project name (without extension) |
| `configuration` | `String` | Build configuration (Debug, Release, etc.) |
| `buildSettingsParameters` | `[String]` | Build settings to extract |
| `setupCommands` | `[SetupCommand]?` | Commands to execute before analyzing each commit (optional) |
| `setupCommands[].command` | `String` | Shell command to execute |
| `setupCommands[].workingDirectory` | `String?` | Directory relative to repo root (optional) |
| `setupCommands[].optional` | `Bool?` | If `true`, analysis continues even if command fails (default: `false`) |

## Requirements

- `xcodebuild` command-line tool
