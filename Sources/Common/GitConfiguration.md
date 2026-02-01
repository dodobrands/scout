# Git Configuration

Git operations configuration shared across all tools. All parameters are optional.

## CLI Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--repo-path, -r <path>` | current directory | Path to repository |
| `--git-clean` | `false` | Clean working directory before analysis (`git clean -ffdx && git reset --hard HEAD`) |
| `--fix-lfs` | `false` | Fix broken LFS pointers by committing modified files after checkout |
| `--initialize-submodules` | `false` | Initialize submodules (reset and update to correct commits) |

## JSON Configuration

Add optional `git` section to your config file. All fields are optional:

```json
{
  "git": {
    "repoPath": "/path/to/repo",
    "clean": true,
    "initializeSubmodules": true
  }
}
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `repoPath` | `String` | current directory | Path to repository |
| `clean` | `Bool` | `false` | Run `git clean -ffdx && git reset --hard HEAD` before analysis |
| `fixLFS` | `Bool` | `false` | Fix broken LFS pointers by committing modified files after checkout |
| `initializeSubmodules` | `Bool` | `false` | Initialize and update git submodules |

> **Note:** CLI flags take priority over config values.

## Operations

### Clean (`--git-clean` / `clean`)

Runs `git clean -ffdx && git reset --hard HEAD` before each commit analysis:
- Removes untracked files and directories
- Removes ignored files
- Resets all changes to HEAD

Useful for repositories with generated files or build artifacts.

### Fix LFS (`--fix-lfs` / `fixLFS`)

Fixes repositories with broken LFS commits where:
- Files are marked as LFS-tracked
- But actual content wasn't uploaded to LFS storage
- Files appear modified after checkout (containing LFS pointer text instead of actual content)

These "modified" files can't be reverted by `git clean` or `git reset` — they persist across checkouts and block switching between commits. The fix commits these files locally (without push) to allow analysis to continue.

### Initialize Submodules (`--initialize-submodules` / `initializeSubmodules`)

Runs submodule initialization and update:
- `git submodule deinit --all -f`
- `git submodule update --init`

Ensures submodules are at correct commits for each analyzed commit.
