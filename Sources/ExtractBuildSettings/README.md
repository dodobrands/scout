# build-settings

Extract build settings from Xcode projects.

## Usage

```bash
swift run scout build-settings \
  --repo-path /path/to/ios/repo \
  --config extract-build-settings-config.json \
  --commits "abc123,def456"
```

## Arguments

### Required

- `--repo-path, -r <path>` — Path to repository
- `--commits, -c <hashes>` — Comma-separated list of commit hashes to analyze

### Optional

- `--config <path>` — Path to configuration JSON file (default: `extract-build-settings-config.json`)
- `--verbose, -v` — Enable verbose logging
- `--initialize-submodules, -I` — Initialize submodules (reset and update to correct commits)

## Configuration

Create `extract-build-settings-config.json`:

```json
{
  "workingDirectory": "DodoPizza",
  "setupCommands": [
    "mise install",
    "tuist install",
    "tuist generate --no-open"
  ],
  "buildSettingsParameters": ["SWIFT_VERSION", "IPHONEOS_DEPLOYMENT_TARGET"],
  "workspaceName": "DodoPizza",
  "configuration": "Debug"
}
```

### Fields

- `workingDirectory` — Directory where setup commands run (relative to repo root)
- `setupCommands` — Commands to execute before analyzing
- `buildSettingsParameters` — Build settings to extract
- `workspaceName` — Xcode workspace/project name (without extension)
- `configuration` — Build configuration (Debug, Release, etc.)

## Requirements

- `xcodebuild` command-line tool
- For Tuist projects: `tuist` CLI

## See Also

- [AGENTS.md](../../AGENTS.md) — General project documentation
