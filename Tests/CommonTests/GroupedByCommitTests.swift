import Common
import OrderedCollections
import Testing

struct TestMetric: CommitResolvable {
    let name: String
    let commits: [String]

    func withResolvedCommits(_ commits: [String]) -> TestMetric {
        TestMetric(name: name, commits: commits)
    }
}

@Suite("groupedByCommit")
struct GroupedByCommitTests {

    @Test("preserves chronological order of commits")
    func preservesOrder() {
        let metrics = [
            TestMetric(name: "A", commits: ["commit-1", "commit-2", "commit-3"]),
            TestMetric(name: "B", commits: ["commit-1", "commit-3"]),
        ]

        let grouped = metrics.groupedByCommit()

        #expect(Array(grouped.keys) == ["commit-1", "commit-2", "commit-3"])
    }

    @Test("groups metrics belonging to the same commit")
    func groupsMetrics() {
        let metrics = [
            TestMetric(name: "A", commits: ["commit-1"]),
            TestMetric(name: "B", commits: ["commit-1"]),
        ]

        let grouped = metrics.groupedByCommit()

        #expect(grouped.count == 1)
        #expect(grouped["commit-1"]?.map(\.name) == ["A", "B"])
    }

    @Test("returns empty dictionary for empty input")
    func emptyInput() {
        let metrics: [TestMetric] = []
        let grouped = metrics.groupedByCommit()
        #expect(grouped.isEmpty)
    }

    @Test("handles metrics with no commits")
    func metricsWithNoCommits() {
        let metrics = [
            TestMetric(name: "A", commits: []),
            TestMetric(name: "B", commits: ["commit-1"]),
        ]

        let grouped = metrics.groupedByCommit()

        #expect(grouped.count == 1)
        #expect(grouped["commit-1"]?.map(\.name) == ["B"])
    }

    @Test("preserves order with many commits")
    func manyCommits() {
        let commitHashes = (1...100).map { "hash-\(String(format: "%03d", $0))" }
        let metrics = [
            TestMetric(name: "metric", commits: commitHashes),
        ]

        let grouped = metrics.groupedByCommit()

        #expect(Array(grouped.keys) == commitHashes)
    }
}
