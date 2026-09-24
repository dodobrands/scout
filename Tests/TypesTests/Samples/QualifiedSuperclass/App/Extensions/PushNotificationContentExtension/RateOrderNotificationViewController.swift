import RateOrderNotificationHandler

// Shares its name with the module's superclass, reached only through the qualified reference.
final class RateOrderNotificationViewController:
    RateOrderNotificationHandler.RateOrderNotificationViewController
{}

final class OrderPagesNotificationViewController:
    RateOrderNotificationHandler.PagedNotificationViewController<OrderPage>
{}
