import Common
import Testing

struct ChecksOutCommitsTests {
    let git = GitConfiguration(
        repoPath: ".",
        clean: true,
        fixLFS: false,
        initializeSubmodules: false
    )

    @Test
    func `When every metric uses HEAD, should not check out commits`() {
        let metrics = [TestMetric(name: "A", commits: ["HEAD"])]

        #expect(!Git.checksOutCommits(for: metrics, git: git))
    }

    @Test
    func `When any metric names an explicit commit, should check out commits`() {
        let metrics = [
            TestMetric(name: "A", commits: ["HEAD"]),
            TestMetric(name: "B", commits: ["abc123"]),
        ]

        #expect(Git.checksOutCommits(for: metrics, git: git))
    }

    @Test
    func `When there are no metrics, should check out commits`() {
        #expect(Git.checksOutCommits(for: [TestMetric](), git: git))
    }
}
