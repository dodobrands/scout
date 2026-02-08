extension BuildSettingsSDK {
    /// Represents a setup command to execute before analysis.
    public struct SetupCommand: Sendable {
        public let command: String
        public let workingDirectory: String?
        public let optional: Bool

        public init(command: String, workingDirectory: String? = nil, optional: Bool = false) {
            self.command = command
            self.workingDirectory = workingDirectory
            self.optional = optional
        }
    }
}
