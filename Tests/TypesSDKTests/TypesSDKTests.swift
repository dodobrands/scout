import Common
import Foundation
import Testing

@testable import TypesSDK

struct TypesSDKTests {
    let sut = TypesSDK()

    @Test
    func `When searching for UIView types, should find all UIView subclasses`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "UIView")

        #expect(result.typeName == "UIView")
        #expect(result.types.names == ["AwesomeView", "DodoView"])
    }

    @Test
    func `When searching for SwiftUI View types, should find all View conformances`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "View")

        #expect(result.typeName == "View")
        // HelloView uses `View`, QualifiedView uses `SwiftUI.View` - both should be found
        #expect(result.types.names == ["HelloView", "QualifiedView"])
    }

    @Test
    func `When searching with wildcard pattern, should match all generic variants`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "JsonAsyncRequest<*>")

        #expect(result.typeName == "JsonAsyncRequest<*>")
        #expect(result.types.names == ["CancelOrderRequest", "OrderListRequest", "ProfileRequest"])
    }

    @Test
    func `When searching without wildcard, should not match generic variants`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "JsonAsyncRequest")

        #expect(result.types.isEmpty)
    }

    @Test
    func `When searching for non-existent type, should return empty result`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "NonExistentType")

        #expect(result.types.isEmpty)
    }

    @Test
    func `When searching for protocol, should find all conforming types`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "Coordinator")

        #expect(
            result.types.names == [
                "AppCoordinator", "AuthCoordinator", "FlowCoordinator", "MenuCoordinator",
            ]
        )
    }

    @Test
    func `When searching for child protocol, should find only direct conformances`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "FlowCoordinator")

        #expect(result.types.names == ["AuthCoordinator", "MenuCoordinator"])
    }

    @Test
    func `When type has deep inheritance chain, should find all descendants`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "BaseViewModel")

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
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "ListViewModel")

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
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let trackableResult = try await sut.countTypes(input: input, typeName: "Trackable")
        let loggableResult = try await sut.countTypes(input: input, typeName: "Loggable")

        #expect(trackableResult.types.names == ["BaseService", "OrderService", "PaymentService"])
        #expect(loggableResult.types.names == ["BaseService", "OrderService", "PaymentService"])
    }

    @Test
    func `When searching for multiple types, should return results for each`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let uiViewResult = try await sut.countTypes(input: input, typeName: "UIView")
        let viewResult = try await sut.countTypes(input: input, typeName: "View")

        #expect(uiViewResult.typeName == "UIView")
        #expect(uiViewResult.types.names == ["AwesomeView", "DodoView"])
        #expect(viewResult.typeName == "View")
        #expect(viewResult.types.names == ["HelloView", "QualifiedView"])
    }

    @Test
    func `When searching for types inside extensions, should find nested types`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "AnalyticsEvent")

        #expect(result.typeName == "AnalyticsEvent")
        #expect(result.types.names == ["CloseScreenEvent", "OpenScreenEvent", "TapButtonEvent"])
    }

    @Test
    func `When searching for types nested in classes, should find all levels`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "Component")

        #expect(result.typeName == "Component")
        #expect(result.types.names == ["DeepComponent", "InnerComponent", "InnerEnum"])
    }

    @Test
    func `When searching for types in extensions of external types, should find them`() async throws
    {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "Formatter")

        #expect(result.typeName == "Formatter")
        #expect(result.types.names == ["CurrencyFormatter", "DateFormatter"])
    }

    @Test
    func `When type has multiple conformances, should find regardless of order`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "EventProtocol")

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
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "Component")

        let innerComponent = try #require(result.types.first { $0.name == "InnerComponent" })
        let deepComponent = try #require(result.types.first { $0.name == "DeepComponent" })

        #expect(innerComponent.fullName == "Container.InnerComponent")
        #expect(deepComponent.fullName == "Container.NestedContainer.DeepComponent")
    }

    @Test
    func `When searching for types, should return relative file path`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "UIView")

        let awesomeView = try #require(result.types.first { $0.name == "AwesomeView" })

        #expect(awesomeView.path == "Views/UIViews.swift")
    }

    @Test
    func `When type is top-level, fullName should equal name`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "UIView")

        let awesomeView = try #require(result.types.first { $0.name == "AwesomeView" })

        #expect(awesomeView.fullName == "AwesomeView")
    }

    @Test
    func `When type is inside extension, fullName should include extended type`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "AnalyticsEvent")

        let openScreenEvent = try #require(result.types.first { $0.name == "OpenScreenEvent" })

        #expect(openScreenEvent.fullName == "Analytics.OpenScreenEvent")
    }

    @Test
    func `When type conforms and its extension has nested conforming type, should find both`()
        async throws
    {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "Screen")

        #expect(result.typeName == "Screen")
        #expect(result.types.names == ["MainScreen", "NestedScreen"])
    }

    @Test
    func `When searching for actor types, should find all conforming actors`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "DataProvider")

        #expect(result.typeName == "DataProvider")
        #expect(result.types.names == ["CacheProvider", "NetworkProvider"])
    }

    @Test
    func `When searching for enum types, should find all conforming enums`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "Action")

        #expect(result.typeName == "Action")
        #expect(result.types.names == ["SystemAction", "UserAction"])
    }

    @Test
    func `When searching for generic types, should find all variants`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "Repository")

        #expect(result.typeName == "Repository")
        #expect(
            result.types.names == ["BaseRepository", "ConstrainedRepository", "GenericRepository"]
        )
    }

    @Test
    func `When types have different access modifiers, should find all`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "InternalProtocol")

        #expect(result.typeName == "InternalProtocol")
        #expect(
            result.types.names == [
                "FileprivateType", "InternalType", "PrivateType", "PublicType",
            ]
        )
    }

    @Test
    func `When same name types in different containers, should find both`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "WidgetProtocol")

        #expect(result.typeName == "WidgetProtocol")
        #expect(result.types.names == ["Widget", "Widget"])
        #expect(result.types.map(\.fullName) == ["Dashboard.Widget", "Settings.Widget"])
    }

    @Test
    func `When searching for property wrappers, should find all`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let result = try await sut.countTypes(input: input, typeName: "Wrapper")

        #expect(result.typeName == "Wrapper")
        #expect(result.types.names == ["BindingWrapper", "StateWrapper"])
    }

    @Test
    func `When type conforms to multiple protocols, should be found by each`() async throws {
        let samplesURL = try samplesDirectory()
        let input = TypesSDK.AnalysisInput(repoPath: samplesURL.path)

        let identifiableResult = try await sut.countTypes(input: input, typeName: "Identifiable")
        let nameableResult = try await sut.countTypes(input: input, typeName: "Nameable")

        #expect(identifiableResult.types.names == ["Company", "Person"])
        #expect(nameableResult.types.names == ["Company", "Person"])
    }
}

private func samplesDirectory() throws -> URL {
    guard let url = Bundle.module.resourceURL?.appendingPathComponent("Samples") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return url
}

extension [TypesSDK.TypeInfo] {
    var names: [String] {
        map { $0.name }
    }
}
