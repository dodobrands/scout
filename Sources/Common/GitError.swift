import Foundation

public enum GitError: Error {
    case commitNotFound(hash: String)
    case invalidRepository(path: URL)
    case gitCommandFailed(command: String, exitCode: Int32)
}

extension GitError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .commitNotFound(let hash):
            return "Commit not found: \(hash)"
        case .invalidRepository(let path):
            return "Invalid git repository at path: \(path.path(percentEncoded: false))"
        case .gitCommandFailed(let command, let exitCode):
            return "Git command failed: '\(command)' (exit code: \(exitCode))"
        }
    }
}
