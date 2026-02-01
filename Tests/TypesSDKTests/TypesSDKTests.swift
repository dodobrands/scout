import Common
import Foundation
import Testing
import TypesSDK

struct TypesSDKTests {
    let sut = TypesSDK()

    @Test
    func `When searching for UIView types, should find all UIView subclasses`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration(repoPath: samplesURL.path)
        let input = TypesInput(git: gitConfig, types: ["UIView"])

        let result = try await sut.countTypes(typeName: "UIView", input: input)

        #expect(result.typeName == "UIView")
        #expect(result.types == ["AwesomeView", "DodoView"])
    }

    @Test
    func `When searching for SwiftUI View types, should find all View conformances`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration(repoPath: samplesURL.path)
        let input = TypesInput(git: gitConfig, types: ["View"])

        let result = try await sut.countTypes(typeName: "View", input: input)

        #expect(result.typeName == "View")
        #expect(result.types == ["HelloView"])
    }

    @Test
    func `When searching with wildcard pattern, should match all generic variants`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration(repoPath: samplesURL.path)
        let input = TypesInput(git: gitConfig, types: ["JsonAsyncRequest<*>"])

        let result = try await sut.countTypes(typeName: "JsonAsyncRequest<*>", input: input)

        #expect(result.typeName == "JsonAsyncRequest<*>")
        #expect(result.types == ["CancelOrderRequest", "OrderListRequest", "ProfileRequest"])
    }

    @Test
    func `When searching without wildcard, should not match generic variants`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration(repoPath: samplesURL.path)
        let input = TypesInput(git: gitConfig, types: ["JsonAsyncRequest"])

        let result = try await sut.countTypes(typeName: "JsonAsyncRequest", input: input)

        #expect(result.types.isEmpty)
    }

    @Test
    func `When searching for non-existent type, should return empty result`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration(repoPath: samplesURL.path)
        let input = TypesInput(git: gitConfig, types: ["NonExistentType"])

        let result = try await sut.countTypes(typeName: "NonExistentType", input: input)

        #expect(result.types.isEmpty)
    }

    @Test
    func `When searching for protocol, should find all conforming types`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration(repoPath: samplesURL.path)
        let input = TypesInput(git: gitConfig, types: ["Coordinator"])

        let result = try await sut.countTypes(typeName: "Coordinator", input: input)

        #expect(
            result.types == [
                "AppCoordinator", "AuthCoordinator", "FlowCoordinator", "MenuCoordinator",
            ]
        )
    }

    @Test
    func `When searching for child protocol, should find only direct conformances`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration(repoPath: samplesURL.path)
        let input = TypesInput(git: gitConfig, types: ["FlowCoordinator"])

        let result = try await sut.countTypes(typeName: "FlowCoordinator", input: input)

        #expect(result.types == ["AuthCoordinator", "MenuCoordinator"])
    }

    @Test
    func `When type has deep inheritance chain, should find all descendants`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration(repoPath: samplesURL.path)
        let input = TypesInput(git: gitConfig, types: ["BaseViewModel"])

        let result = try await sut.countTypes(typeName: "BaseViewModel", input: input)

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
        let gitConfig = GitConfiguration(repoPath: samplesURL.path)
        let input = TypesInput(git: gitConfig, types: ["ListViewModel"])

        let result = try await sut.countTypes(typeName: "ListViewModel", input: input)

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
        let gitConfig = GitConfiguration(repoPath: samplesURL.path)
        let input = TypesInput(git: gitConfig, types: ["Trackable", "Loggable"])

        let trackableResult = try await sut.countTypes(typeName: "Trackable", input: input)
        let loggableResult = try await sut.countTypes(typeName: "Loggable", input: input)

        #expect(trackableResult.types == ["BaseService", "OrderService", "PaymentService"])
        #expect(loggableResult.types == ["BaseService", "OrderService", "PaymentService"])
    }

    @Test
    func `When searching for multiple types, should return results for each`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration(repoPath: samplesURL.path)
        let input = TypesInput(git: gitConfig, types: ["UIView", "View"])

        let results = try await sut.countTypes(input: input)

        #expect(results.count == 2)
        #expect(results[0].typeName == "UIView")
        #expect(results[0].types == ["AwesomeView", "DodoView"])
        #expect(results[1].typeName == "View")
        #expect(results[1].types == ["HelloView"])
    }
}

private func samplesDirectory() throws -> URL {
    guard let url = Bundle.module.resourceURL?.appendingPathComponent("Samples") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return url
}
