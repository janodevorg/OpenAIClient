import Foundation
import Get

/// Convenience initializer for `Get.Request`.
public extension Request {
    enum HTTPMethod: String {
        case get
        case delete
        case post
    }
    init( // swiftlint:disable:this function_default_parameter_at_end
        method: HTTPMethod = .get,
        url: URL,
        query: [(String, String?)]? = nil,
        body: Encodable? = nil,
        headers: [String: String]? = nil,
        id: String? = nil
    ) {
        self.init(
            method: method.rawValue,
            url: url.absoluteString,
            query: query,
            body: body,
            headers: headers,
            id: id
        )
    }
}
