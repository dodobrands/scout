---
name: scout-types
description: Count Swift types by inheritance with `scout types`. Trigger when the question is about how many types derive from a base, e.g. "how many UIViewControllers do we have?", "list every SwiftUI View in this repo", "how many XCTestCase subclasses are left?", "count our BaseCoordinator subclasses", "track adoption of our new Repository<*> base class across commits since january", "did UIKit screens shrink over the last year?", "which files declare UIView subclasses?". Resolves inheritance through the source and through the Xcode SDK, so `UICollectionViewCell` subclasses count as `UIView`.
---

# `scout types`

Count types that inherit from (or conform to) the given base types, at HEAD or across commits.

Run `scout types --help` for flags — it is the source of truth. This file covers what the help does not say.

## Inheritance resolution

Inheritance chains are followed through the analyzed source. A base class that lives outside the source — `class ProductCell: UICollectionViewCell` — is still resolved: scout extracts the real class hierarchy with `swift-symbolgraph-extract` for the modules the source imports, against the **Xcode iOS simulator SDK** specifically. There is no hardcoded UIKit mapping, so `UICollectionViewCell`, `UITableViewCell` and `UIControl` subclasses all land under `UIView`.

Protocol conformance written in the source counts too: `struct ContentView: View` is found under `View`. What the SDK adds is class inheritance only — `inheritsFrom` edges, never `conformsTo` — so a protocol that refines another protocol *outside* the source is not followed.

Consequences worth stating out loud when reporting numbers:

- On Linux, or when Xcode is unavailable, resolution degrades silently to source-only — the same repository yields lower counts.
- The same degradation hits a macOS/AppKit codebase **on a Mac**: only the iOS simulator SDK is queried, so `NSControl` subclasses never roll up into `NSView`. Counting AppKit hierarchies is source-only in practice.
- Each imported module is extracted once and cached across commits. The first UIKit extraction adds a few seconds to the run.

## Config shape

```json
{
  "metrics": [
    { "type": "UIView" },
    { "type": "UIViewController", "commits": ["abc123", "def456"] },
    { "type": "BaseCoordinator<*>" }
  ],
  "git": { "repoPath": "/path/to/repo", "clean": true }
}
```

`<*>` matches any generic variant — `BaseCoordinator<*>` catches `BaseCoordinator<SomeFlow>` and `BaseCoordinator<OtherFlow>`. Without it only the exact name matches, and a generic base class scores zero.

Any type name works, not just Apple's: `BaseViewModel`, `FeatureModule`, `QuickSpec`.

## Result shape

```json
{
  "commit": "abc1234def5678",
  "date": "2025-01-15T07:30:00Z",
  "results": [
    {
      "typeName": "UIView",
      "types": [
        { "name": "HeaderView", "fullName": "Components.HeaderView", "path": "Sources/Components/HeaderView.swift" }
      ]
    }
  ]
}
```

`name` is the bare type name, `fullName` is qualified with enclosing types, `path` is relative to the repository root. The count is `types | length` — scout reports the list, not a number.

## Recipes

### Count per type at HEAD

```bash
scout types UIView UIViewController View --output /tmp/types.json
jq -r '.[] | .results[] | "\(.typeName)\t\(.types | length)"' /tmp/types.json
```

### UIKit-to-SwiftUI migration as a time series

```bash
jq -r '.[] | .date as $d | .results[] | [$d, .typeName, (.types | length)] | @csv' /tmp/types.json
```

### Where the remaining subclasses live

```bash
jq -r '.[-1].results[] | select(.typeName == "UIViewController") | .types[].path' /tmp/types.json \
  | sed 's|/[^/]*$||' | sort | uniq -c | sort -rn
```

## Don't

- Don't compare counts taken on macOS with counts taken on Linux — SDK resolution changes them.
- Don't expect AppKit base classes to resolve through the SDK; the extraction targets the iOS simulator.
- Don't write a generic base class without `<*>` and report the zero as fact.
- Don't expect a protocol declared in a dependency and refined by another one there to be followed — the SDK contributes class inheritance only. Direct conformance written in your source is fine; indirect protocol refinement isn't.

## See also

- `scout-pattern` — occurrences of arbitrary text when inheritance isn't the question.
- `scout` (umbrella) — output envelope, per-metric commits, `--git-clean` footgun, detached HEAD after a run.
