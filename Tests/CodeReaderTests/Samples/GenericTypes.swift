import Foundation

// Base generic class
open class JsonAsyncRequest<Dto>: JsonRequest<Dto> where Dto: Decodable {}

// Base non-generic class for indirect inheritance test
open class JsonRequest<Dto> {
}

// Types that inherit from JsonAsyncRequest with generic parameters
public final class CancelOrderRequest: JsonAsyncRequest<CancelOrderDTO>, RequiresAuthorization {
}

public final class OrderListRequest: JsonAsyncRequest<OrdersInfoDTO>, RequiresAuthorization {
}

public final class ProfileRequest: JsonAsyncRequest<ProfileDTO> {
}

// Type that doesn't inherit from JsonAsyncRequest
public final class SomeOtherRequest: JsonRequest<String> {
}
