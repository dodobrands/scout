extension TypesSDK {
    /// Information about a found type.
    public struct TypeInfo: Sendable, Encodable, Equatable {
        /// Simple type name (e.g., "AddToCartEvent")
        public let name: String
        /// Full qualified type name (e.g., "Analytics.AddToCartEvent")
        public let fullName: String
        /// Relative path to the file containing this type
        public let path: String

        public init(name: String, fullName: String, path: String) {
            self.name = name
            self.fullName = fullName
            self.path = path
        }
    }

    /// A single types result item.
    public struct ResultItem: Sendable, Encodable {
        public let typeName: String
        public let types: [TypeInfo]

        public init(typeName: String, types: [TypeInfo]) {
            self.typeName = typeName
            self.types = types
        }
    }

    /// Output of types analysis for a single commit.
    public struct Output: Sendable, Encodable {
        public let commit: String
        public let date: String
        public let results: [ResultItem]

        public init(commit: String, date: String, results: [ResultItem]) {
            self.commit = commit
            self.date = date
            self.results = results
        }
    }

    /// Result of type counting operation.
    public struct Result: Sendable, Encodable, Equatable {
        public let commit: String
        public let typeName: String
        public let types: [TypeInfo]

        public init(commit: String = "", typeName: String, types: [TypeInfo]) {
            self.commit = commit
            self.typeName = typeName
            self.types = types
        }
    }
}
