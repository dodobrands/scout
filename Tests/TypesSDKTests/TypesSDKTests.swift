import Foundation
import Testing
import TypesSDK

struct TypesSDKTests {
    let sut = TypesSDK()

    @Test
    func `When searching for UIView types, should find all UIView subclasses`() async throws {
        let samplesURL = try samplesDirectory()

        let result = try await sut.countTypes(in: samplesURL, typeName: "UIView")

        #expect(result.typeName == "UIView")
        #expect(result.types == ["AwesomeView", "DodoView"])
    }

    @Test
    func `When searching for SwiftUI View types, should find all View conformances`() async throws {
        let samplesURL = try samplesDirectory()

        let result = try await sut.countTypes(in: samplesURL, typeName: "View")

        #expect(result.typeName == "View")
        #expect(result.types == ["HelloView"])
    }

    @Test
    func `When searching with wildcard pattern, should match all generic variants`() async throws {
        let samplesURL = try samplesDirectory()

        let result = try await sut.countTypes(in: samplesURL, typeName: "JsonAsyncRequest<*>")

        #expect(result.typeName == "JsonAsyncRequest<*>")
        #expect(result.types == ["CancelOrderRequest", "OrderListRequest", "ProfileRequest"])
    }

    @Test
    func `When searching without wildcard, should not match generic variants`() async throws {
        let samplesURL = try samplesDirectory()

        let result = try await sut.countTypes(in: samplesURL, typeName: "JsonAsyncRequest")

        #expect(result.types.isEmpty)
    }

    @Test
    func `When searching for non-existent type, should return empty result`() async throws {
        let samplesURL = try samplesDirectory()

        let result = try await sut.countTypes(in: samplesURL, typeName: "NonExistentType")

        #expect(result.types.isEmpty)
    }

    @Test
    func `When searching for protocol, should find all conforming types`() async throws {
        let samplesURL = try samplesDirectory()

        let result = try await sut.countTypes(in: samplesURL, typeName: "Coordinator")

        #expect(
            result.types == [
                "AppCoordinator", "AuthCoordinator", "FlowCoordinator", "MenuCoordinator",
            ]
        )
    }

    @Test
    func `When searching for child protocol, should find only direct conformances`() async throws {
        let samplesURL = try samplesDirectory()

        let result = try await sut.countTypes(in: samplesURL, typeName: "FlowCoordinator")

        #expect(result.types == ["AuthCoordinator", "MenuCoordinator"])
    }

    @Test
    func `When type has deep inheritance chain, should find all descendants`() async throws {
        let samplesURL = try samplesDirectory()

        let result = try await sut.countTypes(in: samplesURL, typeName: "BaseViewModel")

        #expect(
            result.types == [
                "ListViewModel",
                "OrdersListViewModel",
                "PaginatedListViewModel",
                "ProductsListViewModel",
            ]
        )
    }

    @Test
    func `When searching middle of inheritance chain, should find only descendants`() async throws {
        let samplesURL = try samplesDirectory()

        let result = try await sut.countTypes(in: samplesURL, typeName: "ListViewModel")

        #expect(
            result.types == [
                "OrdersListViewModel", "PaginatedListViewModel", "ProductsListViewModel",
            ]
        )
    }

    @Test
    func `When type conforms to multiple protocols, should be found by each protocol`() async throws
    {
        let samplesURL = try samplesDirectory()

        let trackableResult = try await sut.countTypes(in: samplesURL, typeName: "Trackable")
        let loggableResult = try await sut.countTypes(in: samplesURL, typeName: "Loggable")

        #expect(trackableResult.types == ["BaseService", "OrderService", "PaymentService"])
        #expect(loggableResult.types == ["BaseService", "OrderService", "PaymentService"])
    }
}

private func samplesDirectory() throws -> URL {
    guard let url = Bundle.module.resourceURL?.appendingPathComponent("Samples") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return url
}
