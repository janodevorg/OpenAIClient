import Foundation

public struct RetrieveFileResponse: Codable {
    public var id: String
    public var object: String
    public var bytes: Int
    public var createdAt: Int
    public var filename: String
    public var purpose: String

    public init(id: String, object: String, bytes: Int, createdAt: Int, filename: String, purpose: String) {
        self.id = id
        self.object = object
        self.bytes = bytes
        self.createdAt = createdAt
        self.filename = filename
        self.purpose = purpose
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.id = try values.decode(String.self, forKey: "id")
        self.object = try values.decode(String.self, forKey: "object")
        self.bytes = try values.decode(Int.self, forKey: "bytes")
        self.createdAt = try values.decode(Int.self, forKey: "created_at")
        self.filename = try values.decode(String.self, forKey: "filename")
        self.purpose = try values.decode(String.self, forKey: "purpose")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encode(id, forKey: "id")
        try values.encode(object, forKey: "object")
        try values.encode(bytes, forKey: "bytes")
        try values.encode(createdAt, forKey: "created_at")
        try values.encode(filename, forKey: "filename")
        try values.encode(purpose, forKey: "purpose")
    }
}
