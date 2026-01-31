import Foundation

public class FileFinder {
  public static func pathToFile(named name: String, in path: URL) -> URL? {
    let fileManager = FileManager.default
    let enumerator = fileManager.enumerator(at: path, includingPropertiesForKeys: nil)

    while let element = enumerator?.nextObject() as? URL {
      if element.lastPathComponent == name {
        return element
      }
    }
    return nil
  }
}
