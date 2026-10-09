extension SwiftParser {
    /// Lookup tables over the analysis pool, built once per commit so that resolving a parent
    /// is a dictionary lookup rather than a scan of every source, package and SDK type.
    /// Buckets keep the pool's order, so the first match still wins: sources, then package
    /// checkouts, then the SDK.
    struct ObjectIndex: Sendable {
        let byName: [String: [ObjectFromCode]]
        let byFullName: [String: [ObjectFromCode]]
        /// Candidates for each module-qualified reference (`Module.Widget`): the `Widget`s whose
        /// file lives under a `Module` directory, and which are not nested typealiases.
        let byModuleQualifiedName: [String: [ObjectFromCode]]

        init(_ objects: [ObjectFromCode]) {
            let byName = Dictionary(grouping: objects, by: \.name)
            self.byName = byName
            byFullName = Dictionary(grouping: objects, by: \.fullName)

            var byModuleQualifiedName: [String: [ObjectFromCode]] = [:]
            for inheritedType in objects.lazy.flatMap(\.inheritedTypes) {
                let reference = String(inheritedType.prefix { $0 != "<" })
                let components = reference.split(separator: ".")
                guard components.count > 1, let module = components.first,
                    let name = components.last
                else { continue }
                let key = "\(module).\(name)"
                guard byModuleQualifiedName[key] == nil else { continue }
                let moduleDirectory = "/\(module)/"
                byModuleQualifiedName[key] = (byName[String(name)] ?? []).filter {
                    !($0.isTypealias && $0.isNested) && $0.filePath.contains(moduleDirectory)
                }
            }
            self.byModuleQualifiedName = byModuleQualifiedName
        }
    }
}
