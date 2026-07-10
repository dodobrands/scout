import SwiftUI

// Reproduces the SwiftUI-into-UIKit misbucketing observed in dodo-mobile-ios.
//
// Reuses `DodoView` (a UIView subclass declared in Views/UIViews.swift) so the
// legitimate `UIView` metric is unchanged; only the phantom conformers below
// must be excluded.

// MARK: - Defect: nested `View` typealias shadows the SwiftUI `View` protocol

// Real DUIKit component pattern: a component exposes its UIKit view through a
// *nested* `View` typealias (fullName `BadgeComponent.View`).
enum BadgeComponent {
    typealias View = DodoView
}

// A reference type that conforms to the SwiftUI `View` protocol. It must NOT be
// counted as a UIView subclass just because a nested `BadgeComponent.View`
// typealias happens to alias a UIView subclass — a nested member typealias is
// only reachable as `BadgeComponent.View`, never as bare `View`.
final class ReferenceSwiftUIView: View {
    var body: some View { Text("reference") }
}

// MARK: - Defect: a value type cannot inherit from a class

// A top-level alias whose target is a UIKit view. Survives nested-typealias
// scoping, so only the value-type rule can exclude the conformer below.
typealias Panel = DodoView

// A value type whose inheritance list resolves to a class must NOT be counted as
// inheriting that class — structs and enums cannot subclass a class.
struct ValueTypePanel: Panel {}
