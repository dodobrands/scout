import Common
import Testing

struct AnalyzesWorkingTreeTests {
    let git = GitConfiguration(
        repoPath: ".",
        clean: true,
        fixLFS: false,
        initializeSubmodules: false
    )

    @Test
    func `When every metric uses HEAD, should analyze the working tree`() {
        let metrics = [
            TestMetric(name: "A", commits: ["HEAD"]),
            TestMetric(name: "B", commits: ["HEAD", "HEAD"]),
        ]

        #expect(metrics.analyzesWorkingTree(git: git))
    }

    @Test
    func `When any metric names an explicit commit, should check out commits`() {
        let metrics = [
            TestMetric(name: "A", commits: ["HEAD"]),
            TestMetric(name: "B", commits: ["abc123"]),
        ]

        #expect(!metrics.analyzesWorkingTree(git: git))
    }
}
