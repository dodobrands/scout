# types

Count Swift types by inheritance across git history.

## Usage

```bash
scout types \
  --repo-path /path/to/repo \
  --commits "abc123,def456"
```

## Arguments

### Required

- `--repo-path, -r <path>` — Path to repository with Swift sources

### Optional

- `--config <path>` — Path to configuration JSON file
- `--commits, -c <hashes>` — Comma-separated list of commit hashes to analyze (default: HEAD)
- `--output, -o <path>` — Path to save JSON results
- `--verbose, -v` — Enable verbose logging
- `--initialize-submodules, -I` — Initialize submodules (reset and update to correct commits)

## Configuration (Optional)

Configuration file is optional. Pass it via `--config` flag:

```bash
scout types --repo-path /path/to/repo --config types-config.json
```

### JSON Format

```json
{
  "types": ["UIView", "UIViewController", "View", "XCTestCase"]
}
```

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `types` | `[String]` | Types to count by inheritance |

### Supported Types

- `UIView` — UIKit view classes
- `UIViewController` — UIKit view controller classes
- `View` — SwiftUI view structs
- `XCTestCase` — XCTest framework test classes

## See Also

- [CodeReader](../CodeReader/README.md) — Code parsing library