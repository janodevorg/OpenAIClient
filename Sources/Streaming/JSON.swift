import Foundation

/// Convenience methods to convert Encodable/Decodable objects to/from JSON string representation.
enum JSON {
    /**
     Returns a value of the type you specify, decoded from a JSON string.
    - Parameter string: The string to encode as JSON.
    - Returns: The object decoded from the JSON string.
    - Throws: `DecodingError` An indication that the data is corrupted or otherwise invalid.
    */
    static func fromString<T: Decodable>(_ string: String) throws -> T? {
        guard let data = string.data(using: .utf8) else { return nil }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
