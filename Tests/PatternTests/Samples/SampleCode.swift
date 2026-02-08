import Foundation
import Testing

// swiftlint:disable all

class SampleViewController: UIViewController {
    // TODO: Refactor this method
    func loadData() {
        // FIXME: Handle error properly
        print("Loading...")
    }
}

// MARK: - Analytics

class AnalyticsService {
    // periphery:ignore
    func track(_ event: String) {}

    // periphery:ignore
    func trackScreen(_ name: String) {}
}

// MARK: - Legacy Code

// TODO: Remove deprecated API usage
@available(*, deprecated)
class LegacyManager {
    // FIXME: Memory leak here
    var cache: [String: Any] = [:]
}
