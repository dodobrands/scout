import Foundation
import Testing

@testable import Types

struct PackageCheckoutsTests {
    let sut = Types(hierarchyProvider: StubHierarchyProvider())

    @Test
    func `Subclasses of a SwiftPM package class are found`() async throws {
        let repo = try makeRepository(checkoutsDirectory: ".build/checkouts")
        defer { try? FileManager.default.removeItem(at: repo) }

        let input = Types.AnalysisInput(repoPath: repo.path, typeName: "UIViewController")
        let result = try await sut.countTypes(input: input)

        #expect(result.types.names == ["OrdersStateViewController", "ProfileStateViewController"])
    }

    @Test
    func `Subclasses of a Tuist-managed package class are found`() async throws {
        let repo = try makeRepository(checkoutsDirectory: "Tuist/.build/checkouts")
        defer { try? FileManager.default.removeItem(at: repo) }

        let input = Types.AnalysisInput(repoPath: repo.path, typeName: "UIViewController")
        let result = try await sut.countTypes(input: input)

        #expect(result.types.names == ["OrdersStateViewController", "ProfileStateViewController"])
    }

    @Test
    func `Package types are not reported`() async throws {
        let repo = try makeRepository(checkoutsDirectory: ".build/checkouts")
        defer { try? FileManager.default.removeItem(at: repo) }

        let input = Types.AnalysisInput(repoPath: repo.path, typeName: "UIViewController")
        let result = try await sut.countTypes(input: input)

        // `StateViewController` and `LoadingViewController` are declared in the package.
        #expect(!result.types.names.contains("StateViewController"))
        #expect(!result.types.names.contains("LoadingViewController"))
    }

    @Test
    func `Without package checkouts, package subclasses are not resolved`() async throws {
        let repo = try makeRepository(checkoutsDirectory: nil)
        defer { try? FileManager.default.removeItem(at: repo) }

        let input = Types.AnalysisInput(repoPath: repo.path, typeName: "UIViewController")
        let result = try await sut.countTypes(input: input)

        #expect(result.types.isEmpty)
    }
}

/// Builds a temporary repository from `Samples/PackageDependency`: the app sources at the root
/// and the package sources under `checkoutsDirectory`. Checkouts live in hidden `.build`
/// directories, which can't be kept in the test resources.
private func makeRepository(checkoutsDirectory: String?) throws -> URL {
    guard
        let samples = Bundle.module.resourceURL?
            .appendingPathComponent("Samples/PackageDependency")
    else {
        throw CocoaError(.fileNoSuchFile)
    }
    let fileManager = FileManager.default
    let repo = fileManager.temporaryDirectory.appending(path: "scout-\(UUID().uuidString)")
    try fileManager.createDirectory(at: repo, withIntermediateDirectories: true)
    try fileManager.copyItem(
        at: samples.appending(path: "App"),
        to: repo.appending(path: "App")
    )
    if let checkoutsDirectory {
        let checkouts = repo.appending(path: checkoutsDirectory)
        try fileManager.createDirectory(
            at: checkouts.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try fileManager.copyItem(at: samples.appending(path: "Checkouts"), to: checkouts)
    }
    return repo
}
