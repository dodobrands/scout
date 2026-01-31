# CodeReader

Swift AST parsing library for analyzing Swift and Kotlin source code.

## What It Does

- Parses Swift source files using SourceKitten to extract class definitions and inheritance relationships
- Reads import statements from Swift files
- Extracts feature toggles from iOS (`FeatureFlag.swift`, `FeatureCode.swift`) and Android (`FeatureCode.kt`) files
- Provides structured data about code structure (classes, imports, toggles)

## Architecture

- **`CodeReader`** — Main service for parsing Swift files and extracting class/import information
- **`PizzaCodeTogglesReader`** — Specialized reader for extracting feature toggles from iOS and Android code
- **`Toggle`** — Data structure representing a feature toggle with name and type (local/firebase/mapi)

## Usage

### Parsing Swift Files

```swift
import CodeReader

let reader = CodeReader()
let fileURL = URL(fileURLWithPath: "/path/to/file.swift")

// Parse file and get all objects
let objects = try reader.parseFile(from: fileURL)

// Check if an object inherits from a base class
let isUIView = reader.isInherited(
    objectFromCode: someObject,
    from: "UIView",
    allObjects: objects
)

// Read imports from a file
let imports = try reader.readImports(from: fileURL)
// Returns: ["UIKit", "SwiftUI", "Foundation"]
```

### Reading Feature Toggles

#### iOS Toggles

```swift
import CodeReader

let togglesReader = PizzaCodeTogglesReader()
let togglesFile = URL(fileURLWithPath: "/path/to/FeatureFlag.swift")

// Read iOS toggles
let toggles = try await togglesReader.readiOSToggles(togglesFile: togglesFile)
// Returns: Set<Toggle>

for toggle in toggles {
    print("\(toggle.name): \(toggle.type)")  // e.g., "Alien: .mapi"
}
```

#### Android Toggles

```swift
let togglesFile = URL(fileURLWithPath: "/path/to/FeatureCode.kt")
let toggles = try await togglesReader.readAndroidToggles(togglesFile: togglesFile)
// Returns: Set<Toggle>
```

## API Reference

### `CodeReader`

#### `parseFile(from:)`

Parses a Swift source file and returns all code objects (classes, structs, enums).

**Parameters:**
- `from fileURL: URL` — Path to Swift source file

**Returns:** Array of parsed code objects

**Example:**
```swift
let objects = try reader.parseFile(from: fileURL)
```

#### `isInherited(objectFromCode:from:allObjects:)`

Checks if a code object inherits from a specific base class. Supports both regular and generic types.

**Parameters:**
- `objectFromCode: ObjectFromCode` — The object to check
- `from baseClass: String` — Base class name (e.g., "UIView", "UIViewController", "JsonAsyncRequest")
- `allObjects: [ObjectFromCode]` — All objects from the parsed file

**Returns:** `Bool` — `true` if the object inherits from the base class

**Generic Types Support:**
The method correctly handles generic types. When SourceKitten parses a class inheriting from a generic base class, it returns the full generic type name (e.g., `"JsonAsyncRequest<CancelOrderDTO>"`). The method matches this against the base type name (e.g., `"JsonAsyncRequest"`) by:
- Checking if the inherited type exactly matches the base type
- Checking if the inherited type starts with `"BaseType<"` (for generic types)
- Recursively checking indirect inheritance through parent types

**Examples:**
```swift
// Regular inheritance
let isView = reader.isInherited(
    objectFromCode: myClass,
    from: "UIView",
    allObjects: objects
)

// Generic inheritance - matches "JsonAsyncRequest<SomeDTO>" to "JsonAsyncRequest"
let isJsonRequest = reader.isInherited(
    objectFromCode: cancelOrderRequest,
    from: "JsonAsyncRequest",
    allObjects: objects
)
```

**Example with generic types:**
```swift
// Source code:
// open class JsonAsyncRequest<Dto>: JsonRequest<Dto> { }
// public final class CancelOrderRequest: JsonAsyncRequest<CancelOrderDTO> { }

// This will return true:
reader.isInherited(
    objectFromCode: cancelOrderRequest,
    from: "JsonAsyncRequest",  // Matches "JsonAsyncRequest<CancelOrderDTO>"
    allObjects: objects
)
```

#### `readImports(from:)`

Extracts import statements from a Swift file.

**Parameters:**
- `from fileURL: URL` — Path to Swift source file

**Returns:** `[String]` — Array of import module names

**Example:**
```swift
let imports = try reader.readImports(from: fileURL)
// Returns: ["UIKit", "SwiftUI", "Foundation"]
```

### `PizzaCodeTogglesReader`

#### `readiOSToggles(togglesFile:)`

Extracts feature toggles from iOS toggle files (`FeatureFlag.swift` or `FeatureCode.swift`).

**Parameters:**
- `togglesFile: URL` — Path to iOS toggle file

**Returns:** `Set<Toggle>` — Set of toggles with their types

**Supported Formats:**
- String-based enums with raw values (e.g., `FeatureCode.emailReceipt = "emailReceipt"`)
- Plain enums (e.g., `enum FeatureFlag { case alien }`)
- Handles namespace prefixes like `LocalFeature.`, `FirebaseFeature.`

**Example:**
```swift
let toggles = try await togglesReader.readiOSToggles(togglesFile: fileURL)
```

#### `readAndroidToggles(togglesFile:)`

Extracts feature toggles from Android toggle files (`FeatureCode.kt`).

**Parameters:**
- `togglesFile: URL` — Path to Android toggle file

**Returns:** `Set<Toggle>` — Set of toggles with their types

**Supported Formats:**
- New format: Enum with `FeatureCodeType` (e.g., `ALIEN("Alien", FeatureCodeType.MAPI)`)
- Legacy format: `object FeatureCode` with `const val` declarations

**Example:**
```swift
let toggles = try await togglesReader.readAndroidToggles(togglesFile: fileURL)
```

### `Toggle`

```swift
public struct Toggle: Equatable, Hashable, Sendable {
    public let name: String
    public let type: ToggleType
}

public enum ToggleType: String, Equatable, Hashable, Sendable {
    case local
    case firebase
    case mapi
}
```

Represents a feature toggle with its name and type. The type indicates where the toggle is configured:
- `.local` — Local feature flag
- `.firebase` — Firebase Remote Config
- `.mapi` — Mobile API (MAPI)

## Toggle Type Detection

### iOS

Toggle types are detected from raw value prefixes:
- `"LocalFeature.*"` → `.local`
- `"FirebaseFeature.*"` → `.firebase`
- Default → `.mapi`

### Android

Toggle types are parsed from enum definitions:
- `FeatureCodeType.LOCAL` → `.local`
- `FeatureCodeType.FIREBASE` → `.firebase`
- `FeatureCodeType.MAPI` → `.mapi`

## Dependencies

- **SourceKitten** (0.36.0+) — Swift AST parsing
- **Common** — Shared utilities (FileError, Logging)
- **Foundation** — File and URL handling
- **Logging** — Structured logging

## See Also

- [CountToggles](../CountToggles/README.md) — Uses CodeReader to count toggles across git history
- [CountTypes](../CountTypes/README.md) — Uses CodeReader to count types by inheritance
