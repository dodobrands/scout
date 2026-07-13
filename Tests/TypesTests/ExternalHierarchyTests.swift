import Foundation
import Testing

@testable import Types

struct ExternalHierarchyTests {
    @Test
    func `Subclasses of UIKit view types resolve to UIView via external hierarchy`() async throws {
        let cellsURL = try cellsSamplesDirectory()
        let provider = StubHierarchyProvider(edges: [
            "UICollectionViewCell": "UICollectionReusableView",
            "UICollectionReusableView": "UIView",
            "UITableViewCell": "UIView",
            "UIControl": "UIView",
            "UIButton": "UIControl",
            "UIView": "UIResponder",
        ])
        let sut = Types(hierarchyProvider: provider)

        let input = Types.AnalysisInput(repoPath: cellsURL.path, typeName: "UIView")
        let result = try await sut.countTypes(input: input)

        #expect(
            result.types.names == [
                "LikeButton", "OrderTableCell", "PriceControl", "ProductCollectionCell",
            ]
        )
    }

    @Test
    func `Without external hierarchy, UIKit subclasses are not resolved to UIView`() async throws {
        let cellsURL = try cellsSamplesDirectory()
        let sut = Types(hierarchyProvider: StubHierarchyProvider())

        let input = Types.AnalysisInput(repoPath: cellsURL.path, typeName: "UIView")
        let result = try await sut.countTypes(input: input)

        #expect(result.types.isEmpty)
    }

    @Test
    func `Direct base class is still found when external hierarchy is present`() async throws {
        let cellsURL = try cellsSamplesDirectory()
        let provider = StubHierarchyProvider(edges: [
            "UIControl": "UIView",
            "UIButton": "UIControl",
        ])
        let sut = Types(hierarchyProvider: provider)

        let input = Types.AnalysisInput(repoPath: cellsURL.path, typeName: "UIControl")
        let result = try await sut.countTypes(input: input)

        #expect(result.types.names == ["LikeButton", "PriceControl"])
    }
}
