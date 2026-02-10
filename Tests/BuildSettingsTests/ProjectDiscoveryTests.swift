import Foundation
import Testing

@testable import BuildSettings

struct ProjectDiscoveryTests {

    @Test
    func `discovers xcodeproj matching include pattern`() async throws {
        let samplesURL = try samplesDirectory()

        let projects = try await ProjectDiscovery.discoverProjects(
            in: samplesURL,
            include: ["**/*.xcodeproj"],
            exclude: []
        )

        #expect(projects.count == 1)
        let project = try #require(projects.first)
        #expect(project.path.hasSuffix("TestApp.xcodeproj"))
    }

    @Test
    func `returns empty when include pattern does not match`() async throws {
        let samplesURL = try samplesDirectory()

        let projects = try await ProjectDiscovery.discoverProjects(
            in: samplesURL,
            include: ["NonExistent/**/*.xcodeproj"],
            exclude: []
        )

        #expect(projects.isEmpty)
    }

    @Test
    func `exclude pattern filters out matching projects`() async throws {
        let samplesURL = try samplesDirectory()

        let projects = try await ProjectDiscovery.discoverProjects(
            in: samplesURL,
            include: ["**/*.xcodeproj"],
            exclude: ["TestApp.xcodeproj"]
        )

        #expect(projects.isEmpty)
    }

    @Test
    func `exact path in include pattern works`() async throws {
        let samplesURL = try samplesDirectory()

        let projects = try await ProjectDiscovery.discoverProjects(
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
