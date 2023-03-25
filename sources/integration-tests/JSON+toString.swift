import Foundation
@testable import OpenAIClient

extension JSON {
    /**
    Returns a JSON-encoded representation of the value you supply.
    - Parameter encodable: The value to encode as JSON.
    - Returns: The encoded JSON string.
    - Throws: `EncodingError` An indication that an encoder or its containers could not encode the given value.
    */
    static func toString<T: Encodable>(_ encodable: T) throws -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return String(data: try encoder.encode(encodable), encoding: .utf8)
    }
}
