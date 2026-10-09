import Common
import Testing

struct AnalyzesWorkingTreeTests {

    @Test
    func `When every metric uses HEAD, should analyze the working tree`() {
        let metrics = [
            TestMetric(name: "A", commits: ["HEAD"]),
            TestMetric(name: "B", commits: ["HEAD", "HEAD"]),
        ]

        #expect(metrics.analyzesWorkingTree)
    }

    @Test
    func `When any metric names an explicit commit, should check out commits`() {
        let metrics = [
            TestMetric(name: "A", commits: ["HEAD"]),
            TestMetric(name: "B", commits: ["abc123"]),
        ]

        #expect(!metrics.analyzesWorkingTree)
    }
}
