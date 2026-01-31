import Foundation
import Logging
import LoggingOSLog

public enum LoggingSetup {
  public static func setup(verbose: Bool) {
    let logLevel: Logger.Level = verbose ? .debug : .info

    LoggingSystem.bootstrap { label in
      var handlers: [LogHandler] = []

      if ProcessInfo.processInfo.environment["GITHUB_ACTIONS"] == "true" {
        var githubHandler = GitHubActionsLogHandler(label: label)
        githubHandler.logLevel = logLevel
        handlers.append(githubHandler)
      } else {
        var osLogHandler = LoggingOSLog(label: label)
        osLogHandler.logLevel = logLevel
        handlers.append(osLogHandler)

        var streamHandler = StreamLogHandler.standardOutput(label: label)
        streamHandler.logLevel = logLevel
        handlers.append(streamHandler)
      }

      return MultiplexLogHandler(handlers)
    }
  }
}
