import Foundation

/// Directory holding the isolated `UICollectionViewCell` / `UITableViewCell` / `UIControl`
/// subclass samples used by external-hierarchy tests.
func cellsSamplesDirectory() throws -> URL {
    guard let url = Bundle.module.resourceURL?.appendingPathComponent("Samples/Cells") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return url
}
