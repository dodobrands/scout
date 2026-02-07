import Foundation

// MARK: - Protocol conformance

protocol Coordinator {}
protocol FlowCoordinator: Coordinator {}

final class AppCoordinator: Coordinator {}
final class AuthCoordinator: FlowCoordinator {}
final class MenuCoordinator: FlowCoordinator {}

// MARK: - Deep inheritance chain (3+ levels)

class BaseViewModel {}
class ListViewModel: BaseViewModel {}
class PaginatedListViewModel: ListViewModel {}
final class OrdersListViewModel: PaginatedListViewModel {}
final class ProductsListViewModel: PaginatedListViewModel {}

// MARK: - Multiple inheritance (class + protocols)

protocol Trackable {}
protocol Loggable {}

class BaseService: Trackable, Loggable {}
final class OrderService: BaseService {}
final class PaymentService: BaseService, Sendable {}

// MARK: - Multiple conformances with different order

protocol EventProtocol {}

struct FirstConformanceEvent: Codable, EventProtocol {}
struct SecondConformanceEvent: EventProtocol, Codable {}
struct MiddleConformanceEvent: Codable, EventProtocol, Sendable {}

// MARK: - Nested types in extensions

protocol AnalyticsEvent {}

enum Analytics {}

extension Analytics {
    struct OpenScreenEvent: AnalyticsEvent {}
    struct CloseScreenEvent: AnalyticsEvent {}
}

extension Analytics {
    struct TapButtonEvent: AnalyticsEvent {}
}

// MARK: - Nested types inside classes/structs

protocol Component {}

class Container {
    struct InnerComponent: Component {}
    class NestedContainer {
        struct DeepComponent: Component {}
    }
}

struct OuterStruct {
    enum InnerEnum: Component {}
}

// MARK: - Types in file-level extensions (extending external types)

protocol Formatter {}

extension String {
    struct DateFormatter: Formatter {}
}

extension Int {
    struct CurrencyFormatter: Formatter {}
}

// MARK: - Type with conformance + extension with nested conforming type

protocol Screen {}

struct MainScreen: Screen {}

extension MainScreen {
    struct NestedScreen: Screen {}
}

// MARK: - Actor types

protocol DataProvider {}

actor CacheProvider: DataProvider {}
actor NetworkProvider: DataProvider {}

// MARK: - Enum with cases

protocol Action {}

enum UserAction: Action {
    case login
    case logout
}

enum SystemAction: Action {
    case refresh
}

// MARK: - Generic types with constraints

protocol Repository {}

struct GenericRepository<T>: Repository {}
struct ConstrainedRepository<T: Codable>: Repository {}
class BaseRepository<T, U>: Repository {}

// MARK: - Access control modifiers

protocol InternalProtocol {}

private struct PrivateType: InternalProtocol {}
private struct FileprivateType: InternalProtocol {}
internal struct InternalType: InternalProtocol {}
public struct PublicType: InternalProtocol {}

// MARK: - Same name in different containers (namespacing)

protocol WidgetProtocol {}

enum Dashboard {
    struct Widget: WidgetProtocol {}
}

enum Settings {
    struct Widget: WidgetProtocol {}
}

// MARK: - Property wrappers

protocol Wrapper {}

@propertyWrapper
struct StateWrapper: Wrapper {
    var wrappedValue: Int
}

@propertyWrapper
struct BindingWrapper<T>: Wrapper {
    var wrappedValue: T
}

// MARK: - Protocol composition in inheritance list

protocol Identifiable {}
protocol Nameable {}

struct Person: Identifiable, Nameable {}
struct Company: Nameable, Identifiable {}
