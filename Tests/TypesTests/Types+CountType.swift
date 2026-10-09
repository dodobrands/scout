import Testing

@testable import Types

extension Types.AnalysisInput {
    init(repoPath: String, typeName: String) {
        self.init(repoPath: repoPath, typeNames: [typeName])
    }
}

extension Types {
    /// Counts a single base type, for tests that check one type at a time.
    func countType(input: AnalysisInput) async throws -> Result {
        try #require(try await countTypes(input: input).first)
    }
}
