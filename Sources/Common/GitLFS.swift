import Foundation
import System

public class GitLFS {
  public static func fixBrokenLFS(in repoPath: URL) async throws {
    let repoPathFilePath = FilePath(repoPath.path(percentEncoded: false))
    let gitDiff = try await Shell.execute(
      "git",
      arguments: ["ls-files", "-m"],
      workingDirectory: repoPathFilePath
    )
    // there may be broken git-lfs commits in pizza
    // file types marked as stored under lfs, but files aren't there actually
    if !gitDiff.isEmpty {
      try await Shell.execute(
        "git",
        arguments: ["add", "-A"],
        workingDirectory: repoPathFilePath
      )
      try await Shell.execute(
        "git",
        arguments: ["commit", "-m", "LFS Fix"],
        workingDirectory: repoPathFilePath
      )
    }
  }

  public static func fixSubmodules(in repoPath: URL) async throws {
    let repoPathFilePath = FilePath(repoPath.path(percentEncoded: false))
    // Reset submodules to the commit specified in the parent repository
    // This fixes cases where submodules point to different commits after checkout
    try await Shell.execute(
      "git",
      arguments: ["submodule", "update", "--init", "--recursive"],
      workingDirectory: repoPathFilePath
    )
  }
}
