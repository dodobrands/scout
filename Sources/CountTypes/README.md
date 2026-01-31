# types

Count Swift types by inheritance across git history.

## Usage

```bash
swift run scout types \
  --ios-sources /path/to/ios/repo \
  --config count-types-config.json \
  --commits "abc123,def456"
```

## Arguments

### Required

- `--ios-sources, -i <path>` — Path to iOS repository
- `--commits, -c <hashes>` — Comma-separated list of commit hashes to analyze

### Optional

- `--config <path>` — Path to configuration JSON file (default: `count-types-config.json`)
- `--verbose, -v` — Enable verbose logging
- `--initialize-submodules, -I` — Initialize submodules (reset and update to correct commits)

## Configuration

Create `count-types-config.json`:

```json
{
  "types": ["UIView", "UIViewController", "View", "XCTestCase"]
}
```

## Supported Types

- `UIView` — UIKit view classes
- `UIViewController` — UIKit view controller classes
- `View` — SwiftUI view structs
- `XCTestCase` — XCTest framework test classes

## See Also

- [AGENTS.md](../../AGENTS.md) — General project documentation
- [CodeReader](../CodeReader/README.md) — Code parsing library