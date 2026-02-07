import Common
import Foundation
import Testing

@testable import TypesSDK

struct TypesSDKTests {
    let sut = TypesSDK()

    @Test
    func `When searching for UIView types, should find all UIView subclasses`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "UIView")]
        )

        let results = try await sut.countTypes(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.typeName == "UIView")
        #expect(result.types.names == ["AwesomeView", "DodoView"])
    }

    @Test
    func `When searching for SwiftUI View types, should find all View conformances`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "View")]
        )

        let results = try await sut.countTypes(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.typeName == "View")
        #expect(result.types.names == ["HelloView"])
    }

    @Test
    func `When searching with wildcard pattern, should match all generic variants`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "JsonAsyncRequest<*>")]
        )

        let results = try await sut.countTypes(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.typeName == "JsonAsyncRequest<*>")
        #expect(result.types.names == ["CancelOrderRequest", "OrderListRequest", "ProfileRequest"])
    }

    @Test
    func `When searching without wildcard, should not match generic variants`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "JsonAsyncRequest")]
        )

        let results = try await sut.countTypes(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.types.isEmpty)
    }

    @Test
    func `When searching for non-existent type, should return empty result`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "NonExistentType")]
        )

        let results = try await sut.countTypes(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.types.isEmpty)
    }

    @Test
    func `When searching for protocol, should find all conforming types`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "Coordinator")]
        )

        let results = try await sut.countTypes(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(
            result.types.names == [
                "AppCoordinator", "AuthCoordinator", "FlowCoordinator", "MenuCoordinator",
            ]
        )
    }

    @Test
    func `When searching for child protocol, should find only direct conformances`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "FlowCoordinator")]
        )

        let results = try await sut.countTypes(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.types.names == ["AuthCoordinator", "MenuCoordinator"])
    }

    @Test
    func `When type has deep inheritance chain, should find all descendants`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "BaseViewModel")]
        )

        let results = try await sut.countTypes(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(
            result.types.names == [
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
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "ListViewModel")]
        )

        let results = try await sut.countTypes(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(
            result.types.names == [
                "OrdersListViewModel", "PaginatedListViewModel", "ProductsListViewModel",
            ]
        )
    }

    @Test
    func `When type conforms to multiple protocols, should be found by each protocol`() async throws
    {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let trackableInput = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "Trackable")]
        )
        let loggableInput = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "Loggable")]
        )

        let trackableResults = try await sut.countTypes(input: trackableInput)
        let loggableResults = try await sut.countTypes(input: loggableInput)

        let trackableResult = try #require(trackableResults[safe: 0])
        let loggableResult = try #require(loggableResults[safe: 0])
        #expect(trackableResult.types.names == ["BaseService", "OrderService", "PaymentService"])
        #expect(loggableResult.types.names == ["BaseService", "OrderService", "PaymentService"])
    }

    @Test
    func `When searching for multiple types, should return results for each`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = TypesInput(
            git: gitConfig,
            metrics: [
                TypeMetricInput(type: "UIView"),
                TypeMetricInput(type: "View"),
            ]
        )

        let results = try await sut.countTypes(input: input)

        #expect(results.count == 2)
        let result0 = try #require(results[safe: 0])
        let result1 = try #require(results[safe: 1])
        #expect(result0.typeName == "UIView")
        #expect(result0.types.names == ["AwesomeView", "DodoView"])
        #expect(result1.typeName == "View")
        #expect(result1.types.names == ["HelloView"])
    }

    @Test
    func `When searching for types inside extensions, should find nested types`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "AnalyticsEvent")]
        )

        let results = try await sut.countTypes(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.typeName == "AnalyticsEvent")
        #expect(result.types.names == ["CloseScreenEvent", "OpenScreenEvent", "TapButtonEvent"])
    }

    @Test
    func `When searching for types nested in classes, should find all levels`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "Component")]
        )

        let results = try await sut.countTypes(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.typeName == "Component")
        #expect(result.types.names == ["DeepComponent", "InnerComponent", "InnerEnum"])
    }

    @Test
    func `When searching for types in extensions of external types, should find them`() async throws
    {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "Formatter")]
        )

        let results = try await sut.countTypes(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.typeName == "Formatter")
        #expect(result.types.names == ["CurrencyFormatter", "DateFormatter"])
    }

    @Test
    func `When type has multiple conformances, should find regardless of order`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "EventProtocol")]
        )

        let results = try await sut.countTypes(input: input)

        #expect(results.count == 1)
        let result = try #require(results[safe: 0])
        #expect(result.typeName == "EventProtocol")
        #expect(
            result.types.names == [
                "FirstConformanceEvent", "MiddleConformanceEvent", "SecondConformanceEvent",
            ]
        )
    }

    @Test
    func `When searching for nested types, should return correct fullName`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "Component")]
        )

        let results = try await sut.countTypes(input: input)

        let result = try #require(results[safe: 0])
        let innerComponent = try #require(result.types.first { $0.name == "InnerComponent" })
        let deepComponent = try #require(result.types.first { $0.name == "DeepComponent" })

        #expect(innerComponent.fullName == "Container.InnerComponent")
        #expect(deepComponent.fullName == "Container.NestedContainer.DeepComponent")
    }

    @Test
    func `When searching for types, should return relative file path`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "UIView")]
        )

        let results = try await sut.countTypes(input: input)

        let result = try #require(results[safe: 0])
        let awesomeView = try #require(result.types.first { $0.name == "AwesomeView" })

        #expect(awesomeView.path == "UIViews.swift")
    }

    @Test
    func `When type is top-level, fullName should equal name`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "UIView")]
        )

        let results = try await sut.countTypes(input: input)

        let result = try #require(results[safe: 0])
        let awesomeView = try #require(result.types.first { $0.name == "AwesomeView" })

        #expect(awesomeView.fullName == "AwesomeView")
    }

    @Test
    func `When type is inside extension, fullName should include extended type`() async throws {
        let samplesURL = try samplesDirectory()
        let gitConfig = GitConfiguration.test(repoPath: samplesURL.path)
        let input = TypesInput(
            git: gitConfig,
            metrics: [TypeMetricInput(type: "AnalyticsEvent")]
        )

        let results = try await sut.countTypes(input: input)

        let result = try #require(results[safe: 0])
        let openScreenEvent = try #require(result.types.first { $0.name == "OpenScreenEvent" })

        #expect(openScreenEvent.fullName == "Analytics.OpenScreenEvent")
    }
}

private func samplesDirectory() throws -> URL {
    guard let url = Bundle.module.resourceURL?.appendingPathComponent("Samples") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return url
}

extension GitConfiguration {
    static func test(repoPath: String) -> GitConfiguration {
        GitConfiguration(
            repoPath: repoPath,
            clean: false,
            fixLFS: false,
            initializeSubmodules: false
        )
    }
}

extension [TypesSDK.TypeInfo] {
    var names: [String] {
        map { $0.name }
    }
}
