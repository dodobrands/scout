import Foundation

public enum FileError: Error {
  case fileNotFound(name: String, in: URL)
  case cannotReadFile(path: URL)
  case invalidFileFormat(path: URL, expected: String)
  case resourceNotFound(name: String, extension: String, subdirectory: String?)
}

extension FileError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .fileNotFound(let name, let directory):
      return "File '\(name)' not found in directory: \(directory.path(percentEncoded: false))"
    case .cannotReadFile(let path):
      return "Cannot read file at path: \(path.path(percentEncoded: false))"
    case .invalidFileFormat(let path, let expected):
      return
        "Invalid file format at \(path.path(percentEncoded: false)), expected: \(expected)"
    case .resourceNotFound(let name, let ext, let subdirectory):
      let subdir = subdirectory.map { " in subdirectory '\($0)'" } ?? ""
      return "Resource '\(name).\(ext)' not found\(subdir)"
    }
  }
}
