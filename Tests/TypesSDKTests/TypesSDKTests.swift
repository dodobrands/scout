import Foundation
import Testing
import TypesSDK

struct TypesSDKTests {
    let sut = TypesSDK()

    @Test
    func `When searching for UIView types, should find all UIView subclasses`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesInput(repoPath: samplesURL, typeName: "UIView")

        let result = try await sut.countTypes(input: input)

        #expect(result.typeName == "UIView")
        #expect(result.types == ["AwesomeView", "DodoView"])
    }

    @Test
    func `When searching for SwiftUI View types, should find all View conformances`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesInput(repoPath: samplesURL, typeName: "View")

        let result = try await sut.countTypes(input: input)

        #expect(result.typeName == "View")
        #expect(result.types == ["HelloView"])
    }

    @Test
    func `When searching with wildcard pattern, should match all generic variants`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesInput(repoPath: samplesURL, typeName: "JsonAsyncRequest<*>")

        let result = try await sut.countTypes(input: input)

        #expect(result.typeName == "JsonAsyncRequest<*>")
        #expect(result.types == ["CancelOrderRequest", "OrderListRequest", "ProfileRequest"])
    }

    @Test
    func `When searching without wildcard, should not match generic variants`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesInput(repoPath: samplesURL, typeName: "JsonAsyncRequest")

        let result = try await sut.countTypes(input: input)

        #expect(result.types.isEmpty)
    }

    @Test
    func `When searching for non-existent type, should return empty result`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesInput(repoPath: samplesURL, typeName: "NonExistentType")

        let result = try await sut.countTypes(input: input)

        #expect(result.types.isEmpty)
    }

    @Test
    func `When searching for protocol, should find all conforming types`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesInput(repoPath: samplesURL, typeName: "Coordinator")

        let result = try await sut.countTypes(input: input)

        #expect(
            result.types == [
                "AppCoordinator", "AuthCoordinator", "FlowCoordinator", "MenuCoordinator",
            ]
        )
    }

    @Test
    func `When searching for child protocol, should find only direct conformances`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesInput(repoPath: samplesURL, typeName: "FlowCoordinator")

        let result = try await sut.countTypes(input: input)

        #expect(result.types == ["AuthCoordinator", "MenuCoordinator"])
    }

    @Test
    func `When type has deep inheritance chain, should find all descendants`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesInput(repoPath: samplesURL, typeName: "BaseViewModel")

        let result = try await sut.countTypes(input: input)

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
        let input = TypesInput(repoPath: samplesURL, typeName: "ListViewModel")

        let result = try await sut.countTypes(input: input)

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
        let trackableInput = TypesInput(repoPath: samplesURL, typeName: "Trackable")
        let loggableInput = TypesInput(repoPath: samplesURL, typeName: "Loggable")

        let trackableResult = try await sut.countTypes(input: trackableInput)
        let loggableResult = try await sut.countTypes(input: loggableInput)

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
