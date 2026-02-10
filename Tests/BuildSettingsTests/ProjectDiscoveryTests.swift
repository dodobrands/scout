import Foundation
import Testing

@testable import BuildSettings

@Suite("ProjectDiscovery")
struct ProjectDiscoveryTests {

    @Test
    func `discovers xcodeproj matching include pattern`() throws {
        let samplesURL = try samplesDirectory()

        let projects = ProjectDiscovery.discoverProjects(
            in: samplesURL,
            include: ["**/*.xcodeproj"],
            exclude: []
        )

        #expect(projects.count == 1)
        #expect(projects.first?.path.hasSuffix("TestApp.xcodeproj") == true)
    }

    @Test
    func `returns empty when include pattern does not match`() throws {
        let samplesURL = try samplesDirectory()

        let projects = ProjectDiscovery.discoverProjects(
            in: samplesURL,
            include: ["NonExistent/**/*.xcodeproj"],
            exclude: []
        )

        #expect(projects.isEmpty)
    }

    @Test
    func `exclude pattern filters out matching projects`() throws {
        let samplesURL = try samplesDirectory()

        let projects = ProjectDiscovery.discoverProjects(
            in: samplesURL,
            include: ["**/*.xcodeproj"],
            exclude: ["TestApp.xcodeproj"]
        )

        #expect(projects.isEmpty)
    }

    @Test
    func `does not discover project.xcworkspace inside xcodeproj`() throws {
        let samplesURL = try samplesDirectory()

        let projects = ProjectDiscovery.discoverProjects(
            in: samplesURL,
            include: ["**/*.xcworkspace"],
            exclude: []
        )

        // project.xcworkspace inside .xcodeproj should be skipped
        #expect(projects.isEmpty)
    }

    @Test
    func `exact path in include pattern works`() throws {
        let samplesURL = try samplesDirectory()

        let projects = ProjectDiscovery.discoverProjects(
            in: samplesURL,
            include: ["TestApp.xcodeproj"],
            exclude: []
        )

        #expect(projects.count == 1)
    }
}

private func samplesDirectory() throws -> URL {
    guard let url = Bundle.module.resourceURL?.appendingPathComponent("Samples") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return url
}
