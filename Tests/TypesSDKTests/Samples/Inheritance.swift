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
