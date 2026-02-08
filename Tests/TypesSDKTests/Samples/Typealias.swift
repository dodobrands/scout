import Foundation

// MARK: - Typealias for protocol

protocol Stylable {}

typealias Theme = Stylable

struct DarkTheme: Theme {}
struct LightTheme: Stylable {}

// MARK: - Typealias for class

class BaseRouter {}

typealias Router = BaseRouter

class MainRouter: Router {}
class SettingsRouter: BaseRouter {}

// MARK: - Chained typealias

typealias AppTheme = Theme

struct NeonTheme: AppTheme {}
