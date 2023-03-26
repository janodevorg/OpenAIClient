import Foundation

func encode<T: Encodable>(encodable: T) throws -> String? {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted
    return String(data: try encoder.encode(encodable), encoding: .utf8)
}
