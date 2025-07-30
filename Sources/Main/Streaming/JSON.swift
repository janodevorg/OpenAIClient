import Foundation

public struct JSON {
    enum JSONError: Error {
        case invalidData
        case decodingFailed(Error)
        case encodingFailed(Error)
    }

    /**
    Returns a JSON-encoded representation of the value you supply.
    - Parameter encodable: The value to encode as JSON.
    - Returns: The encoded JSON string.
    - Throws: `EncodingError` An indication that an encoder or its containers could not encode the given value.
    */
    public static func encode(_ codable: Encodable) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        do {
            let jsonData = try encoder.encode(codable)
            return String(decoding: jsonData, as: UTF8.self)
        } catch {
            throw JSONError.encodingFailed(error)
        }
    }

    /**
     Returns a value of the type you specify, decoded from a JSON string.
    - Parameter string: The string to encode as JSON.
    - Returns: The object decoded from the JSON string.
    - Throws: `DecodingError` An indication that the data is corrupted or otherwise invalid.
    */
    public static func decode<T: Decodable>(_ jsonString: String) throws -> T {
        let jsonData = Data(jsonString.utf8)
        do {
            return try JSONDecoder().decode(T.self, from: jsonData)
        } catch {
            throw JSONError.decodingFailed(error)
        }
    }

    /**
     Serializes an object to a JSON string.
    - Parameter object: The object to serialize (must be a JSON-compatible type).
    - Returns: The JSON string representation of the object.
    - Throws: `JSONError.encodingFailed` if serialization fails.
    */
    public static func serialize(_ object: Any) throws -> String {
        do {
            let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
            guard let jsonString = String(data: data, encoding: .utf8) else {
                throw JSONError.encodingFailed(JSONError.invalidData)
            }
            return jsonString
        } catch {
            throw JSONError.encodingFailed(error)
        }
    }

    /**
     Deserializes a JSON string to either a dictionary or an array.
    - Parameter jsonString: The JSON string to deserialize.
    - Returns: The deserialized object as [String: Any] for objects or [Any] for arrays.
    - Throws: `JSONError.decodingFailed` if deserialization fails.
    */
    public static func deserialize(_ jsonString: String) throws -> Any {
        let data = Data(jsonString.utf8)
        do {
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            throw JSONError.decodingFailed(error)
        }
    }
}
