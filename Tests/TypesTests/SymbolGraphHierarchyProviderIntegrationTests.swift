import Foundation
import Testing

@testable import Types

/// End-to-end coverage of the real Xcode-SDK-backed provider.
///
/// Gated behind the `SCOUT_SDK_TESTS` environment variable because it shells out to
/// `swift-symbolgraph-extract` (requires Xcode, ~seconds per module). Run with:
/// `SCOUT_SDK_TESTS=1 swift test --filter SymbolGraphHierarchyProviderIntegrationTests`.
struct SymbolGraphHierarchyProviderIntegrationTests {
    @Test(.enabled(if: ProcessInfo.processInfo.environment["SCOUT_SDK_TESTS"] != nil))
    func `Real Xcode SDK resolves UIKit subclasses to UIView end-to-end`() async throws {
        let cellsURL = try cellsSamplesDirectory()
        let sut = Types(hierarchyProvider: SymbolGraphHierarchyProvider())

        let input = Types.AnalysisInput(repoPath: cellsURL.path, typeName: "UIView")
        let result = try await sut.countTypes(input: input)

        #expect(
            result.types.names == [
                "LikeButton", "OrderTableCell", "PriceControl", "ProductCollectionCell",
            ]
        )
    }
}
