# CodeReader

Swift AST parsing library for analyzing Swift source code.

## What It Does

- Parses Swift source files using SourceKitten to extract class definitions and inheritance relationships
- Provides structured data about code structure (classes, structs, enums)

## Architecture

- **`CodeReader`** — Main service for parsing Swift files and extracting type information

## Usage

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
The method requires explicit wildcard syntax for matching generic types:
- `"JsonAsyncRequest"` — matches only exact `JsonAsyncRequest` (no generics)
- `"JsonAsyncRequest<*>"` — matches any generic variant like `JsonAsyncRequest<CancelOrderDTO>`, `JsonAsyncRequest<SomeDTO>`

When SourceKitten parses a class inheriting from a generic base class, it returns the full generic type name (e.g., `"JsonAsyncRequest<CancelOrderDTO>"`). The method also recursively checks indirect inheritance through parent types.

**Examples:**
```swift
// Regular inheritance
let isView = reader.isInherited(
    objectFromCode: myClass,
    from: "UIView",
    allObjects: objects
)

// Generic inheritance with wildcard - matches "JsonAsyncRequest<SomeDTO>"
let isJsonRequest = reader.isInherited(
    objectFromCode: cancelOrderRequest,
    from: "JsonAsyncRequest<*>",
    allObjects: objects
)

// Exact match - does NOT match "JsonAsyncRequest<SomeDTO>"
let isExactJsonRequest = reader.isInherited(
    objectFromCode: cancelOrderRequest,
    from: "JsonAsyncRequest",
    allObjects: objects
)
```

## See Also

- [Types](../Types/README.md) — Uses CodeReader to count types by inheritance
