# CountTypes

Counts Swift types by inheritance across git history. Finds classes conforming to specific base types and uploads type counts to Google Sheets.

## What It Does

Analyzes Swift source files across git commit history to count types that inherit from or conform to specific base types. Uses SourceKitten for AST parsing to identify inheritance relationships and uploads type counts to Google Sheets.

## Requirements

- Swift 6.2+
- Access to iOS repository
- Google Apps Script Web App endpoint URL
- Git repository with commit history

## Installation

Build from source:

```bash
swift build --product CountTypes
```

Or run directly:

```bash
swift run CountTypes [arguments]
```

## Usage

### Basic Command

```bash
swift run CountTypes \
  --ios-sources /path/to/ios/repo \
  --type UIView \
  --sheet-name pizza-ios \
  --endpoint https://script.google.com/macros/s/.../exec
```

### Arguments

#### Required

- `--ios-sources <path>` — iOS repository path
- `--type <type>` — Base type to count (e.g., `UIView`, `UIViewController`, `View`, `XCTestCase`)
- `--sheet-name <name>` — Google Sheets sheet name to upload data to
- `--endpoint <url>` — Google Apps Script Deployment Web App URL

#### Optional

- `--hash <commit-hash>` — If specified, only this commit will be analyzed (skips commit collection)
- `--branch <branch>` — Git branch to analyze commits from (default: `main`)
- `--interval <seconds>` — Minimum time interval between commits in seconds (default: 86400 = 1 day)
- `--verbose` — Enable verbose logging
- `--dry-run` — Log actions without executing
- `--initialize-submodules` — Initialize submodules (reset and update to correct commits)

## Supported Types

CountTypes can count types inheriting from or conforming to:

- `UIView` — UIKit view classes
- `UIViewController` — UIKit view controller classes
- `View` — SwiftUI view structs/classes
- `XCTestCase` — XCTest framework test classes
- `JsonAsyncRequest` — JSON async request types
- `JsonCallbackableRequest` — JSON callbackable request types
- `VoidAsyncRequest` — Void async request types
- `VoidCallbackableRequest` — Void callbackable request types

## How It Works

1. **Commit Collection**: Finds commits to analyze by:
   - Querying Google Sheets for the last processed commit for the metric
   - Finding commits on the specified branch after that commit
   - Filtering commits by minimum time interval (default: 1 day)
   - Or uses a specific commit hash if `--hash` is provided

2. **Type Analysis**: For each commit:
   - Checks out the commit in the repository
   - Finds all `.swift` files recursively
   - Parses each file using SourceKitten AST
   - Identifies types that inherit from or conform to the specified base type
   - Counts matching types

3. **Data Upload**: Uploads metrics to Google Sheets with:
   - Date (commit timestamp)
   - Commit hash
   - Metric name (the type name, e.g., "UIView")
   - Value (type count)

## Examples

### Basic Usage

```bash
swift run CountTypes \
  --ios-sources ~/Developer/dodo-mobile-ios \
  --type UIView \
  --sheet-name pizza-ios \
  --endpoint https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
```

### Analyze Specific Commit

```bash
swift run CountTypes \
  --ios-sources ~/Developer/dodo-mobile-ios \
  --type UIView \
  --sheet-name pizza-ios \
  --endpoint https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec \
  --hash abc123def456
```

### Custom Branch and Interval

```bash
swift run CountTypes \
  --ios-sources ~/Developer/dodo-mobile-ios \
  --type UIView \
  --sheet-name pizza-ios \
  --endpoint https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec \
  --branch develop \
  --interval 3600
```

### Dry-Run Mode

```bash
swift run CountTypes \
  --ios-sources ~/Developer/dodo-mobile-ios \
  --type UIView \
  --sheet-name pizza-ios \
  --endpoint https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec \
  --dry-run
```

## Output

The tool logs progress and results:

```
Will analyze 5 commits
Found 125 types inherited from UIView at 2024-01-15 10:30:00 +0000, abc123def
Would upload: sheetName="pizza-ios", metric="UIView", value=125
Found 126 types inherited from UIView at 2024-01-16 10:30:00 +0000, def456ghi
Would upload: sheetName="pizza-ios", metric="UIView", value=126
...
Summary: 5 upload(s) performed
```

With verbose logging enabled, it also shows which types were found:

```
Types conforming to UIView: ["CustomView", "AnotherView", ...]
```

## Inheritance Detection

CountTypes uses SourceKitten AST parsing to detect inheritance relationships:

- **Class inheritance**: `class MyView: UIView { }`
- **Protocol conformance**: `struct MyView: View { }`
- **Indirect inheritance**: `class BaseView: UIView { }` and `class DerivedView: BaseView { }` (both counted)
- **Generic types**: `class CancelOrderRequest: JsonAsyncRequest<CancelOrderDTO> { }` (matches base type `JsonAsyncRequest`)

### Generic Types Parsing

When parsing generic types, SourceKitten returns the full generic type name in `key.inheritedtypes`. For example:
- `class CancelOrderRequest: JsonAsyncRequest<CancelOrderDTO>` → SourceKitten returns `"JsonAsyncRequest<CancelOrderDTO>"` in inherited types
- CountTypes matches this against the base type `"JsonAsyncRequest"` by checking if the inherited type starts with `"JsonAsyncRequest<"`

This allows counting types that inherit from generic base classes like:
- `JsonAsyncRequest<Dto>` — matches `"JsonAsyncRequest"`
- `JsonCallbackableRequest<Dto>` — matches `"JsonCallbackableRequest"`
- `VoidAsyncRequest` — matches `"VoidAsyncRequest"`

**Example:**
```swift
// Base generic class
open class JsonAsyncRequest<Dto>: JsonRequest<Dto> { }

// These will all be counted when searching for "JsonAsyncRequest":
public final class CancelOrderRequest: JsonAsyncRequest<CancelOrderDTO> { }
public final class OrderListRequest: JsonAsyncRequest<OrdersInfoDTO> { }
public final class ProfileRequest: JsonAsyncRequest<ProfileDTO> { }
```

Types are sorted alphabetically by name for consistent output.

## Error Handling

Common errors and solutions:

- **"Directory does not exist"**: Check that `--ios-sources` points to a valid directory.
- **"Failed to create enumerator"**: File system access issue. Check permissions.
- **"Invalid URL"**: Check that `--endpoint` is a valid URL.

## Dry-Run Mode

When `--dry-run` is enabled:
- Read operations (commit checkout, file parsing) run normally
- Write operations (Google Sheets uploads) are logged but not executed
- All operations that would run are logged
- Summary shows how many uploads would have been performed

## See Also

- [AGENTS.md](../../AGENTS.md) — General project documentation
- [CodeReader](../../Sources/CodeReader/README.md) — Code parsing library documentation