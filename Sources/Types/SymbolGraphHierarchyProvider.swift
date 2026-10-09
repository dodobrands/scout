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

        let keys = Dictionary(
            uniqueKeysWithValues: modules.map { ($0, "\($0)|\(sdkPath)|\(target)") }
        )
        let uncached = modules.filter { keys[$0].flatMap { cache[$0] } == nil }.sorted()
        if !uncached.isEmpty {
            let extracted = await Self.extract(modules: uncached, sdkPath: sdkPath, target: target)
            for module in uncached {
                if let key = keys[module] { cache[key] = extracted[module] ?? [] }
            }
        }

        // Sorted module order keeps the pool, and so the first match of a name, deterministic.
        return modules.sorted().flatMap { module in keys[module].flatMap { cache[$0] } ?? [] }
    }

    /// Extracts modules in parallel, one `swift-symbolgraph-extract` process per module,
    /// at most one process per core at a time.
    private static func extract(
        modules: [String],
        sdkPath: String,
        target: String
    ) async -> [String: [ObjectFromCode]] {
        let width = max(1, ProcessInfo.processInfo.activeProcessorCount)
        return await withTaskGroup(of: (String, [ObjectFromCode]).self) { group in
            var pending = modules[...]
            var result: [String: [ObjectFromCode]] = [:]

            func addNext() {
                guard let module = pending.popFirst() else { return }
                group.addTask {
                    let objects = await Signposts.interval("Extract symbol graph", module) {
                        await extract(module: module, sdkPath: sdkPath, target: target)
                    }
                    return (module, objects)
                }
            }

            for _ in 0..<width { addNext() }
            for await (module, objects) in group {
                result[module] = objects
                addNext()
            }
            return result
        }
    }

    private static func extract(
        module: String,
        sdkPath: String,
        target: String
    ) async -> [ObjectFromCode] {
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
            // Debug: a module without build products (unbuilt project) fails to
            // extract and is expected. At info this dumps the frontend's full
            // "Current visible modules" list per module — hundreds of lines each.
            logger.debug(
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
