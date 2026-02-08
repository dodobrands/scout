import Foundation
import Testing

@testable import LOCSDK

/// Tests for MetricInput.metricIdentifier placeholder replacement
struct MetricIdentifierTests {

    // MARK: - Default Template Tests

    @Test
    func `default template formats with pipe separator`() throws {
        let metric = LOCSDK.MetricInput(
            languages: ["Swift"],
            include: ["Sources"],
            exclude: []
        )

        #expect(metric.metricIdentifier == "Swift | Sources")
    }

    @Test
    func `default template with multiple languages`() throws {
        let metric = LOCSDK.MetricInput(
            languages: ["Swift", "Objective-C"],
            include: ["Sources"],
            exclude: []
        )

        #expect(metric.metricIdentifier == "Swift, Objective-C | Sources")
    }

    @Test
    func `default template with multiple include paths`() throws {
        let metric = LOCSDK.MetricInput(
            languages: ["Swift"],
            include: ["Sources", "App"],
            exclude: []
        )

        #expect(metric.metricIdentifier == "Swift | Sources, App")
    }

    // MARK: - Custom Template Tests

    @Test
    func `custom template with LOC prefix`() throws {
        let metric = LOCSDK.MetricInput(
            languages: ["Swift"],
            include: ["Sources"],
            exclude: [],
            nameTemplate: "LOC [%langs%] [%include%]"
        )

        #expect(metric.metricIdentifier == "LOC [Swift] [Sources]")
    }

    @Test
    func `custom template with only languages`() throws {
        let metric = LOCSDK.MetricInput(
            languages: ["Swift"],
            include: ["Sources"],
            exclude: [],
            nameTemplate: "%langs%"
        )

        #expect(metric.metricIdentifier == "Swift")
    }

    @Test
    func `custom template with descriptive format`() throws {
        let metric = LOCSDK.MetricInput(
            languages: ["Swift"],
            include: ["Sources"],
            exclude: ["Tests"],
            nameTemplate: "%langs% in %include% (excluding %exclude%)"
        )

        #expect(metric.metricIdentifier == "Swift in Sources (excluding Tests)")
    }

    @Test
    func `custom template with multiple values in all placeholders`() throws {
        let metric = LOCSDK.MetricInput(
            languages: ["Swift", "Objective-C"],
            include: ["Sources", "App"],
            exclude: ["Tests", "Vendor"],
            nameTemplate: "LOC: %langs% | Include: %include% | Exclude: %exclude%"
        )

        #expect(
            metric.metricIdentifier
                == "LOC: Swift, Objective-C | Include: Sources, App | Exclude: Tests, Vendor"
        )
    }

    // MARK: - Edge Cases

    @Test
    func `empty languages defaults to Unknown`() throws {
        let metric = LOCSDK.MetricInput(
            languages: [],
            include: ["Sources"],
            exclude: []
        )

        #expect(metric.metricIdentifier == "Unknown | Sources")
    }

    @Test
    func `empty include defaults to dot`() throws {
        let metric = LOCSDK.MetricInput(
            languages: ["Swift"],
            include: [],
            exclude: []
        )

        #expect(metric.metricIdentifier == "Swift | .")
    }

    @Test
    func `empty exclude produces empty string`() throws {
        let metric = LOCSDK.MetricInput(
            languages: ["Swift"],
            include: ["Sources"],
            exclude: [],
            nameTemplate: "Excluding: %exclude%"
        )

        #expect(metric.metricIdentifier == "Excluding: ")
    }

    @Test
    func `all arrays empty`() throws {
        let metric = LOCSDK.MetricInput(
            languages: [],
            include: [],
            exclude: []
        )

        #expect(metric.metricIdentifier == "Unknown | .")
    }

    @Test
    func `multiple placeholders of same type in template`() throws {
        let metric = LOCSDK.MetricInput(
            languages: ["Swift"],
            include: ["Sources"],
            exclude: [],
            nameTemplate: "%langs% and %langs% again"
        )

        #expect(metric.metricIdentifier == "Swift and Swift again")
    }

    @Test
    func `no placeholders in template`() throws {
        let metric = LOCSDK.MetricInput(
            languages: ["Swift"],
            include: ["Sources"],
            exclude: [],
            nameTemplate: "Fixed String"
        )

        #expect(metric.metricIdentifier == "Fixed String")
    }
}
