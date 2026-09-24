import Foundation

// MARK: - Class-constrained protocols

class ScreenController {}
protocol PaymentScreen: ScreenController {}
protocol CardScreen: PaymentScreen {}

final class CardScreenController: ScreenController, CardScreen {}
final class ThreeDSScreenController: ScreenController {}
