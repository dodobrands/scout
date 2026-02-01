import Foundation
import Logging

package protocol JobSummaryFormattable {
    var markdown: String { get }
}

package struct GitHubActionsLogHandler: LogHandler {
    package var logLevel: Logger.Level = .info

    /// Metadata property required by LogHandler protocol.
    /// Intentionally does not store any data - only metadata from individual log() calls
    /// should be included in GitHub Actions annotations.
    package var metadata: Logger.Metadata {
        get { [:] }
        set {}
    }

    private let label: String

    package init(label: String) {
        self.label = label
    }

    package subscript(metadataKey key: String) -> Logger.Metadata.Value? {
        get { nil }
        set {}
    }

    package func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        guard level >= logLevel else { return }

        let command = workflowCommand(for: level)
        let parameters = formatParameters(
            file: file,
            line: line,
            function: function,
            metadata: metadata
        )

        // Enrich message step by step
        var enrichedMessage = enrichWithMetadata(message, metadata: metadata)
        enrichedMessage = enrichWithGitHubActionsAnnotation(
            enrichedMessage,
            command: command,
            parameters: parameters
        )

        print(enrichedMessage)
    }

    private func enrichWithMetadata(
        _ message: Logger.Message,
        metadata: Logger.Metadata?
    ) -> String {
        guard let metadata = metadata, !metadata.isEmpty else {
            return "\(message)"
        }

        let metadataString = formatMetadataForText(metadata)
        return "\(message) \(metadataString)"
    }

    private func enrichWithGitHubActionsAnnotation(
        _ message: String,
        command: String,
        parameters: String
    ) -> String {
        // If command is empty (info level), return message as-is without GitHub Actions annotations
        guard !command.isEmpty else {
            return message
        }

        // Notice/Warning/Error: wrap message with GitHub Actions annotation format
        if parameters.isEmpty {
            return "::\(command)::\(message)"
        } else {
            return "::\(command) \(parameters)::\(message)"
        }
    }

    private func formatMetadataForText(_ metadata: Logger.Metadata) -> String {
        var pairs: [String] = []

        for (key, value) in metadata.sorted(by: { $0.key < $1.key }) {
            // Skip "title" as it's already used in formatParameters
            if key == "title" {
                continue
            }
            let valueString = formatMetadataValue(value)
            pairs.append("\(key)=\(valueString)")
        }

        return pairs.isEmpty ? "" : pairs.joined(separator: ", ")
    }

    private func formatMetadataValue(_ value: Logger.Metadata.Value) -> String {
        switch value {
        case .string(let str):
            return str
        case .stringConvertible(let convertible):
            return "\(convertible)"
        case .array(let array):
            let items = array.map { formatMetadataValue($0) }
            return "[\(items.joined(separator: ", "))]"
        case .dictionary(let dict):
            let pairs = dict.map { "\($0.key): \(formatMetadataValue($0.value))" }
            return "{\(pairs.joined(separator: ", "))}"
        }
    }

    private func workflowCommand(for level: Logger.Level) -> String {
        switch level {
        case .trace, .debug:
            return "debug"
        case .info:
            return ""  // Plain message without GitHub Actions annotation
        case .notice:
            return "notice"
        case .warning:
            return "warning"
        case .error, .critical:
            return "error"
        }
    }

    private func formatParameters(
        file: String,
        line: UInt,
        function: String,
        metadata: Logger.Metadata?
    ) -> String {
        var params: [String] = []

        let filename = URL(fileURLWithPath: file).lastPathComponent
        params.append("file=\(filename)")
        params.append("line=\(line)")

        let baseTitle: String
        if let title = metadata?["title"]?.description {
            baseTitle = title
        } else {
            baseTitle = function
        }

        let titleWithLabel = "\(label): \(baseTitle)"
        params.append("title=\(escapeValue(titleWithLabel))")

        return params.joined(separator: ",")
    }

    private func escapeValue(_ value: String) -> String {
        value
            .replacingOccurrences(of: "%", with: "%25")
            .replacingOccurrences(of: "\r", with: "%0D")
            .replacingOccurrences(of: "\n", with: "%0A")
            .replacingOccurrences(of: ":", with: "%3A")
            .replacingOccurrences(of: ",", with: "%2C")
    }

    // MARK: - Job Summary

    package static func writeSummary(_ formattable: JobSummaryFormattable) {
        writeSummary(formattable.markdown)
    }

    package static func writeSummary(_ markdown: String) {
        guard let summaryFile = ProcessInfo.processInfo.environment["GITHUB_STEP_SUMMARY"] else {
            return
        }

        guard let fileHandle = FileHandle(forWritingAtPath: summaryFile) else {
            return
        }

        defer {
            try? fileHandle.close()
        }

        do {
            try fileHandle.seekToEnd()
            if let data = markdown.data(using: .utf8) {
                try fileHandle.write(contentsOf: data)
            }
        } catch {
            // Silently fail if we can't write to the summary file
        }
    }
}
