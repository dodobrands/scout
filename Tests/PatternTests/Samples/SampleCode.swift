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

// MARK: - Task patterns for regex testing

func example1() {
    Task { @MainActor in
        print("simple")
    }
}

func example2() {
    Task(priority: .background) { @MainActor in
        print("with priority")
    }
}

class TaskService {
    func example3() {
        Task { @MainActor [weak self] in
            print("with capture list \(String(describing: self))")
        }
    }
}

// MARK: - Force unwrap patterns

func forceUnwraps() {
    let value: String? = "test"
    let forced = value!
    let nested = value!.count
    print(forced, nested)
}

// MARK: - Deprecated API usage

@available(*, deprecated, message: "Use NewAPI")
func oldFunction() {}

@available(iOS, deprecated: 15.0)
func platformDeprecated() {}

// MARK: - Print statements (debug leftover detection)

func debugCode() {
    print("debug value")
    debugPrint("detailed debug")
    NSLog("legacy log")
}

// MARK: - Notification patterns

extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let dataDidUpdate = Notification.Name("dataDidUpdate")
}

// MARK: - Dispatch queue usage

func legacyAsync() {
    DispatchQueue.main.async {
        print("main queue")
    }
    DispatchQueue.global().async {
        print("background")
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        print("delayed")
    }
}

// MARK: - Try patterns

func errorHandling() throws {
    let data = try! JSONDecoder().decode(String.self, from: Data())
    let optional = try? JSONEncoder().encode(data)
    _ = optional
}
