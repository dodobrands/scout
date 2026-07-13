import Foundation
import Logging

// LoggingOSLog wraps os.log and is only available on Apple platforms.
#if canImport(LoggingOSLog)
    import LoggingOSLog
#endif

package enum LoggingSetup {
    package static func setup(verbose: Bool) {
        let logLevel: Logger.Level = verbose ? .debug : .info

        LoggingSystem.bootstrap { label in
            var handlers: [LogHandler] = []

            if ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] == "true" {
                var githubHandler = GitHubActionsLogHandler(label: label)
                githubHandler.logLevel = logLevel
                handlers.append(githubHandler)
            } else {
                #if canImport(LoggingOSLog)
                    var osLogHandler = LoggingOSLog(label: label)
                    osLogHandler.logLevel = logLevel
                    handlers.append(osLogHandler)
                #endif

                var streamHandler = StreamLogHandler.standardOutput(label: label)
                streamHandler.logLevel = logLevel
                handlers.append(streamHandler)
            }

            return MultiplexLogHandler(handlers)
        }
    }
}
