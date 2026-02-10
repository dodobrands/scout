# build-settings

Extract build settings from Xcode projects (.xcodeproj).

## Usage

```bash
# Discover projects via glob and extract settings
scout build-settings --include "**/*.xcodeproj" SWIFT_VERSION IPHONEOS_DEPLOYMENT_TARGET

# Use config file
scout build-settings --config build-settings-config.json

# CLI overrides config
scout build-settings --include "App/**/*.xcodeproj" --config build-settings-config.json

# Analyze specific commits
scout build-settings --include "**/*.xcodeproj" SWIFT_VERSION --commits abc123 def456
```

## Arguments

### Positional

- `<build-settings-parameters>` — Build settings parameters to extract (e.g., SWIFT_VERSION IPHONEOS_DEPLOYMENT_TARGET)

### Required

- `--include <patterns>` — Glob patterns to discover `.xcodeproj` files (e.g., `**/*.xcodeproj`). Required via CLI or config file. Accepts multiple patterns.

### Optional

- `--exclude <patterns>` — Glob patterns to exclude from discovery (e.g., `Pods/**`). Accepts multiple patterns.
- `--config <path>` — Path to configuration JSON file
- `--commits, -c <hashes>` — Commit hashes to analyze (default: HEAD)
- `--output, -o <path>` — Path to save JSON results
- `--verbose, -v` — Enable verbose logging
- `--repo-path, -r <path>` — Path to repository (default: current directory)
- `--git-clean` — Clean working directory before analysis (`git clean -ffdx && git reset --hard HEAD`)
- `--fix-lfs` — Fix broken LFS pointers by committing modified files after checkout
- `--initialize-submodules` — Initialize submodules (reset and update to correct commits)
- `--continue-on-missing-project` — Continue analysis when no projects are found at a commit instead of failing (default: fail)

## Configuration

Configuration file is optional if `--include` is provided via CLI.

> **Note:** CLI flags take priority over config values.

```bash
# CLI only (no config needed)
scout build-settings --include "**/*.xcodeproj" SWIFT_VERSION

# Config only
scout build-settings --config build-settings-config.json

# CLI overrides config
scout build-settings --include "App/**/*.xcodeproj" --config build-settings-config.json
```

### JSON Format

**Minimal:**

```json
{
  "projects": {
    "include": ["**/*.xcodeproj"]
  }
}
```

**With build settings metrics:**

```json
{
  "projects": {
    "include": ["**/*.xcodeproj"],
    "exclude": ["Pods/**"]
  },
  "configuration": "Debug",
  "metrics": [
    { "setting": "SWIFT_VERSION" },
    { "setting": "IPHONEOS_DEPLOYMENT_TARGET" }
  ]
}
```

**With setup commands (e.g., for generated projects):**

```json
{
  "projects": {
    "include": ["DodoPizza/**/*.xcodeproj"],
    "continueOnMissing": true
  },
  "configuration": "Debug",
  "metrics": [
    { "setting": "SWIFT_VERSION" },
    { "setting": "IPHONEOS_DEPLOYMENT_TARGET" }
  ],
  "setupCommands": [
    { "command": "mise install", "optional": true },
    { "command": "tuist install", "workingDirectory": "DodoPizza" },
    { "command": "tuist generate --no-open", "workingDirectory": "DodoPizza" }
  ]
}
```

**With git configuration:**

```json
{
  "projects": {
    "include": ["**/*.xcodeproj"]
  },
  "configuration": "Debug",
  "metrics": [
    { "setting": "SWIFT_VERSION" }
  ],
  "git": {
    "repoPath": "/path/to/repo",
    "clean": true,
    "initializeSubmodules": true
  }
}
```

### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `projects` | `Object` | **Yes*** | Project discovery configuration. *Can be provided via `--include` CLI flag instead. |
| `projects.include` | `[String]` | **Yes** | Glob patterns to discover `.xcodeproj` files (e.g., `["**/*.xcodeproj"]`). |
| `projects.exclude` | `[String]` | No | Glob patterns to exclude (e.g., `["Pods/**"]`). Default: `[]`. |
| `projects.continueOnMissing` | `Bool` | No | If `true`, analysis continues when no projects are found at a commit (default: `false`). See [Generated Projects](#generated-projects). |
| `configuration` | `String` | No | Build configuration (default: "Debug") |
| `metrics` | `[Metric]` | No | Array of build setting metrics to analyze |
| `metrics[].setting` | `String` | Yes | Build setting name (e.g., `SWIFT_VERSION`) |
| `metrics[].commits` | `[String]?` | No | Commits for this setting (default: `["HEAD"]`) |
| `setupCommands` | `[SetupCommand]` | No | Commands to execute before analyzing each commit |
| `setupCommands[].command` | `String` | Yes | Command to execute (simple commands run directly, shell operators like `\|`, `&&` trigger `/bin/sh`) |
| `setupCommands[].workingDirectory` | `String` | No | Directory relative to repo root |
| `setupCommands[].optional` | `Bool` | No | If `true`, analysis continues even if command fails (default: `false`) |
| `git` | `Object` | No | [Git configuration](../Common/GitConfiguration.md) |

### Glob Patterns

Include and exclude patterns support standard glob syntax:

| Pattern | Meaning |
|---------|---------|
| `*` | Matches any characters within a single path segment |
| `**` | Matches any characters across multiple path segments (recursive) |
| `?` | Matches a single character |

Examples:

| Pattern | Matches |
|---------|---------|
| `**/*.xcodeproj` | All `.xcodeproj` files in any directory |
| `DodoPizza/**/*.xcodeproj` | All `.xcodeproj` files under `DodoPizza/` |
| `App/App.xcodeproj` | Specific project at exact path |
| `Pods/**` | Everything under `Pods/` (useful for exclude) |

> **Note:** `project.xcworkspace` bundles inside `.xcodeproj` are automatically excluded from discovery.

### Per-Metric Commits (Config Only)

Different build settings can be analyzed on different commits. This is only available via config file — CLI arguments apply the same commits to all settings.

```json
{
  "projects": {
    "include": ["**/*.xcodeproj"]
  },
  "metrics": [
    { "setting": "SWIFT_VERSION", "commits": ["abc123", "def456"] },
    { "setting": "IPHONEOS_DEPLOYMENT_TARGET", "commits": ["ghi789"] },
    { "setting": "MARKETING_VERSION" },
    { "setting": "CURRENT_PROJECT_VERSION", "commits": [] }
  ]
}
```

| Setting | Analyzed On |
|---------|-------------|
| `SWIFT_VERSION` | `abc123`, `def456` |
| `IPHONEOS_DEPLOYMENT_TARGET` | `ghi789` |
| `MARKETING_VERSION` | `HEAD` (default) |
| `CURRENT_PROJECT_VERSION` | skipped (empty array) |

> **Note:** CLI `--commits` flag overrides all config commits and applies to every setting equally.

## Output Format

When using `--output`, results are saved as JSON array. Each result item represents one requested build setting with target values:

```json
[
  {
    "commit": "abc1234def5678",
    "date": "2025-01-15T07:30:00Z",
    "results": [
      {
        "setting": "SWIFT_VERSION",
        "targets": {
          "MyApp": "5.0",
          "MyAppTests": "5.0"
        }
      },
      {
        "setting": "IPHONEOS_DEPLOYMENT_TARGET",
        "targets": {
          "MyApp": "15.0",
          "MyAppTests": "15.0"
        }
      }
    ]
  }
]
```

**Multiple commits:**
```json
[
  {
    "commit": "abc1234def5678",
    "date": "2025-01-15T07:30:00Z",
    "results": [
      {
        "setting": "SWIFT_VERSION",
        "targets": { "MyApp": "5.0" }
      }
    ]
  },
  {
    "commit": "def5678abc1234",
    "date": "2025-02-15T11:45:00Z",
    "results": [
      {
        "setting": "SWIFT_VERSION",
        "targets": { "MyApp": "5.9" }
      }
    ]
  }
]
```

**When a target does not have a requested setting, the value is `null`:**
```json
{
  "setting": "SWIFT_STRICT_CONCURRENCY",
  "targets": {
    "MyApp": "complete",
    "MyAppTests": null
  }
}
```

**When no projects are found at a commit (with `--continue-on-missing-project`), results contain the requested settings with empty targets:**
```json
{
  "commit": "e18beffdf4",
  "date": "2024-03-10T11:17:36Z",
  "results": [
    { "setting": "SWIFT_VERSION", "targets": {} },
    { "setting": "SWIFT_STRICT_CONCURRENCY", "targets": {} }
  ]
}
```

## Generated Projects

When analyzing repositories with generated Xcode projects (e.g., Tuist, XcodeGen), very old commits may fail because the required tooling or dependencies are no longer available. In such cases, no `.xcodeproj` files may exist after running setup commands.

By default, the tool fails when no projects matching the include patterns are found. Use `--continue-on-missing-project` (or `"continueOnMissing": true` in the `projects` config object) to skip those commits with empty results instead of failing the entire run:

```bash
scout build-settings --config config.json --continue-on-missing-project
```

```json
{
  "projects": {
    "include": ["DodoPizza/**/*.xcodeproj"],
    "continueOnMissing": true
  },
  "setupCommands": [
    { "command": "mise install", "optional": true },
    { "command": "tuist install", "workingDirectory": "DodoPizza", "optional": true },
    { "command": "tuist generate --no-open", "workingDirectory": "DodoPizza", "optional": true }
  ],
  "metrics": [
    { "setting": "SWIFT_STRICT_CONCURRENCY" }
  ]
}
```

## Requirements

- `xcodebuild` command-line tool
