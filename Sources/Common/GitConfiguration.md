# Git Configuration

Git operations configuration shared across all tools. All parameters are optional.

## Working tree without checkout

When no metric names a commit other than `HEAD` — no `--commits` and no `commits` in the config, or only `HEAD` in them — scout analyzes the working tree as is:

- no checkout, the branch stays attached;
- no clean, LFS fix or submodule update, even if enabled: scout logs a warning instead;
- uncommitted and untracked files are analyzed;
- the output reports the `HEAD` hash and date.

Any explicit commit switches the whole run to checkouts, `HEAD` included: once another commit is checked out, the working tree no longer reflects `HEAD`. The options below apply only to such runs.

## CLI Flags

| Flag | Default | Description |
|------|---------|-------------|
| `--repo-path, -r <path>` | current directory | Path to repository |
| `--git-clean` | `false` | Run `git clean -ffdx && git reset --hard HEAD` before each checkout |
| `--fix-lfs` | `false` | Fix broken LFS pointers by committing modified files on each checkout |
| `--initialize-submodules` | `false` | Initialize submodules on each checkout (reset and update to correct commits) |

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
| `clean` | `Bool` | `false` | Run `git clean -ffdx && git reset --hard HEAD` before each checkout |
| `fixLFS` | `Bool` | `false` | Fix broken LFS pointers by committing modified files on each checkout |
| `initializeSubmodules` | `Bool` | `false` | Initialize and update git submodules on each checkout |

> **Note:** CLI flags take priority over config values.

## Operations

### Clean (`--git-clean` / `clean`)

Runs `git clean -ffdx && git reset --hard HEAD` before each checkout:
- Removes untracked files and directories
- Removes ignored files
- Resets all changes to HEAD

Useful for repositories with generated files or build artifacts.

> **Warning:** `git clean -ffdx` removes all untracked files, including config files and output results placed inside the repository. When using `--git-clean`, place `--config` and `--output` paths **outside the repository** (e.g., `$RUNNER_TEMP` on GitHub Actions) or pass all parameters via CLI flags.

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
