import Foundation
import Testing

@testable import Common

@Suite("GlobMatcher")
struct GlobMatcherTests {

    // MARK: - Exact match

    @Test func `exact path matches`() {
        #expect(GlobMatcher.match(path: "App.xcodeproj", pattern: "App.xcodeproj"))
    }

    @Test func `exact path with directory matches`() {
        #expect(
            GlobMatcher.match(path: "DodoPizza/App.xcodeproj", pattern: "DodoPizza/App.xcodeproj")
        )
    }

    @Test func `different exact paths do not match`() {
        #expect(!GlobMatcher.match(path: "Other.xcodeproj", pattern: "App.xcodeproj"))
    }

    // MARK: - Single star (*)

    @Test func `star matches any filename`() {
        #expect(GlobMatcher.match(path: "App.xcodeproj", pattern: "*.xcodeproj"))
    }

    @Test func `star does not match across segments`() {
        #expect(!GlobMatcher.match(path: "Dir/App.xcodeproj", pattern: "*.xcodeproj"))
    }

    @Test func `star in middle matches`() {
        #expect(GlobMatcher.match(path: "Dir/App.xcodeproj", pattern: "Dir/*.xcodeproj"))
    }

    // MARK: - Double star (**)

    @Test func `doublestar matches any depth`() {
        #expect(GlobMatcher.match(path: "A/B/C/App.xcodeproj", pattern: "**/*.xcodeproj"))
    }

    @Test func `doublestar matches zero depth`() {
        #expect(GlobMatcher.match(path: "App.xcodeproj", pattern: "**/*.xcodeproj"))
    }

    @Test func `doublestar at end matches everything`() {
        #expect(GlobMatcher.match(path: "Pods/SomePod/Something.xcodeproj", pattern: "Pods/**"))
    }

    @Test func `doublestar with prefix`() {
        #expect(
            GlobMatcher.match(
                path: "DodoPizza/Modules/Auth/Auth.xcodeproj",
                pattern: "DodoPizza/**/*.xcodeproj"
            )
        )
    }

    @Test func `doublestar does not match wrong prefix`() {
        #expect(
            !GlobMatcher.match(
                path: "Other/Auth/Auth.xcodeproj",
                pattern: "DodoPizza/**/*.xcodeproj"
            )
        )
    }

    // MARK: - Question mark (?)

    @Test func `question mark matches single char`() {
        #expect(GlobMatcher.match(path: "App1.xcodeproj", pattern: "App?.xcodeproj"))
    }

    @Test func `question mark does not match zero chars`() {
        #expect(!GlobMatcher.match(path: "App.xcodeproj", pattern: "App?.xcodeproj"))
    }

    // MARK: - Leading/trailing slashes

    @Test func `strips leading slash from path`() {
        #expect(GlobMatcher.match(path: "/App.xcodeproj", pattern: "App.xcodeproj"))
    }

    @Test func `strips trailing slash from path`() {
        #expect(GlobMatcher.match(path: "App.xcodeproj/", pattern: "App.xcodeproj"))
    }

    @Test func `strips slashes from pattern`() {
        #expect(GlobMatcher.match(path: "App.xcodeproj", pattern: "/App.xcodeproj/"))
    }

    // MARK: - matchesAny

    @Test func `matchesAny returns true if any pattern matches`() {
        let patterns = ["Pods/**", "Carthage/**", "**/*.xcodeproj"]
        #expect(GlobMatcher.matchesAny(path: "Dir/App.xcodeproj", patterns: patterns))
    }

    @Test func `matchesAny returns false if no pattern matches`() {
        let patterns = ["Pods/**", "Carthage/**"]
        #expect(!GlobMatcher.matchesAny(path: "Dir/App.xcodeproj", patterns: patterns))
    }

    // MARK: - Real-world patterns

    @Test func `excludes project.xcworkspace inside xcodeproj`() {
        #expect(
            GlobMatcher.match(
                path: "App.xcodeproj/project.xcworkspace",
                pattern: "**/project.xcworkspace"
            )
        )
    }

    @Test func `matches deeply nested xcodeproj`() {
        #expect(
            GlobMatcher.match(
                path: "DodoPizza/Modules/Feature/Sources/Feature.xcodeproj",
                pattern: "**/*.xcodeproj"
            )
        )
    }
}
