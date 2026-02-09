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

    @Test
    func `When grouping metrics, should preserve input order of commits`() {
        let metrics = [
            TestMetric(name: "A", commits: ["commit-1", "commit-2", "commit-3"]),
            TestMetric(name: "B", commits: ["commit-1", "commit-3"]),
        ]

        let grouped = metrics.groupedByCommit()

        #expect(Array(grouped.keys) == ["commit-1", "commit-2", "commit-3"])
    }

    @Test
    func `When metrics share a commit, should group them together`() {
        let metrics = [
            TestMetric(name: "A", commits: ["commit-1"]),
            TestMetric(name: "B", commits: ["commit-1"]),
        ]

        let grouped = metrics.groupedByCommit()

        #expect(grouped.count == 1)
        #expect(grouped["commit-1"]?.map(\.name) == ["A", "B"])
    }

    @Test
    func `When input is empty, should return empty dictionary`() {
        let metrics: [TestMetric] = []
        let grouped = metrics.groupedByCommit()
        #expect(grouped.isEmpty)
    }

    @Test
    func `When metric has no commits, should skip it`() {
        let metrics = [
            TestMetric(name: "A", commits: []),
            TestMetric(name: "B", commits: ["commit-1"]),
        ]

        let grouped = metrics.groupedByCommit()

        #expect(grouped.count == 1)
        #expect(grouped["commit-1"]?.map(\.name) == ["B"])
    }

    @Test
    func `When grouping many commits, should preserve order`() {
        let commitHashes = (1...100).map { "hash-\(String(format: "%03d", $0))" }
        let metrics = [
            TestMetric(name: "metric", commits: commitHashes)
        ]

        let grouped = metrics.groupedByCommit()

        #expect(Array(grouped.keys) == commitHashes)
    }
}
