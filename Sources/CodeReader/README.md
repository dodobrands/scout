# CodeReader

Swift AST parsing library for analyzing Swift source code.

## What It Does

- Parses Swift source files using SourceKitten to extract class definitions and inheritance relationships
- Reads import statements from Swift files
- Provides structured data about code structure (classes, structs, enums, imports)

## Architecture

- **`CodeReader`** — Main service for parsing Swift files and extracting class/import information

## Usage

### Parsing Swift Files

```swift
import CodeReader

let reader = CodeReader()
let fileURL = URL(fileURLWithPath: "/path/to/file.swift")

// Parse file and get all objects
let objects = try reader.parseFile(from: fileURL)

// Count objects inheriting from UIView
let viewCount = objects.filter { object in
    reader.isInherited(
        objectFromCode: object,
        from: "UIView",
        allObjects: objects
    )
}.count

// Read imports from a file
let imports = try reader.readImports(from: fileURL)
// Returns: ["UIKit", "SwiftUI", "Foundation"]
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

## Dependencies

- **SourceKitten** (0.36.0+) — Swift AST parsing
- **Common** — Shared utilities (FileError, Logging)
- **Foundation** — File and URL handling
- **Logging** — Structured logging

## See Also

- [Types](../Types/README.md) — Uses CodeReader to count types by inheritance
