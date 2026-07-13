import Common
import Foundation
import Logging

/// Resolves external class inheritance by extracting the real hierarchy from the Xcode SDK
/// via `swift-symbolgraph-extract`. No UIKit knowledge is hardcoded — module names come from
/// the source's own imports, and the hierarchy comes from Apple's SDK.
///
/// If the SDK or the extractor is unavailable, or a module cannot be extracted, resolution
/// degrades gracefully to source-only analysis (returns no external objects).
actor SymbolGraphHierarchyProvider: ExternalHierarchyProvider {
    private static let logger = Logger(label: "scout.SymbolGraphHierarchyProvider")

    /// Extracted objects cached per `module|sdk|target`; the SDK hierarchy is stable across
    /// git commits, so each module is extracted at most once per run.
    private var cache: [String: [ObjectFromCode]] = [:]

    func externalObjects(forModules modules: Set<String>) async throws -> [ObjectFromCode] {
        guard let sdkPath = await Self.sdkPath(), let target = Self.target(forSDKPath: sdkPath)
        else {
            Self.logger.info("Xcode SDK unavailable; resolving inheritance from source only")
            return []
        }

        var result: [ObjectFromCode] = []
        for module in modules.sorted() {
            let key = "\(module)|\(sdkPath)|\(target)"
            if let cached = cache[key] {
                result += cached
                continue
            }
            let objects = await extract(module: module, sdkPath: sdkPath, target: target)
            cache[key] = objects
            result += objects
        }
        return result
    }

    private func extract(module: String, sdkPath: String, target: String) async -> [ObjectFromCode]
    {
        let outputDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("scout-symbolgraph-\(module)-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: outputDirectory) }

        do {
            try FileManager.default.createDirectory(
                at: outputDirectory,
                withIntermediateDirectories: true
            )
            try await Shell.execute(
                "xcrun",
                arguments: [
                    "swift-symbolgraph-extract",
                    "-module-name", module,
                    "-sdk", sdkPath,
                    "-target", target,
                    "-output-dir", outputDirectory.path(percentEncoded: false),
                ]
            )

            let files = try FileManager.default.contentsOfDirectory(
                at: outputDirectory,
                includingPropertiesForKeys: nil
            )
            .filter { $0.pathExtension == "json" }

            return try files.flatMap { file in
                try SymbolGraphParser.objects(fromSymbolGraphJSON: Data(contentsOf: file))
            }
        } catch {
            Self.logger.info(
                "Skipping module '\(module)': \(error.localizedDescription)"
            )
            return []
        }
    }

    private static func sdkPath() async -> String? {
        let path = try? await Shell.execute(
            "xcrun",
            arguments: ["--sdk", "iphonesimulator", "--show-sdk-path"]
        )
        guard let path, !path.isEmpty else { return nil }
        return path
    }

    /// Derives a target triple from an SDK path such as `.../iPhoneSimulator26.5.sdk`.
    static func target(forSDKPath sdkPath: String) -> String? {
        guard let name = sdkPath.split(separator: "/").last,
            name.hasPrefix("iPhoneSimulator"),
            name.hasSuffix(".sdk")
        else { return nil }

        let version = name.dropFirst("iPhoneSimulator".count).dropLast(".sdk".count)
        guard !version.isEmpty else { return nil }
        return "\(currentArchitecture)-apple-ios\(version)-simulator"
    }

    private static var currentArchitecture: String {
        #if arch(arm64)
            return "arm64"
        #else
            return "x86_64"
        #endif
    }
}
