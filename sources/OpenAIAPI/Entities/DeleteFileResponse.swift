import Foundation

public struct DeleteFileResponse: Codable {
    public var id: String
    public var object: String
    public var deleted: Bool

    public init(id: String, object: String, deleted: Bool) {
        self.id = id
        self.object = object
        self.deleted = deleted
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: StringCodingKey.self)
        self.id = try values.decode(String.self, forKey: "id")
        self.object = try values.decode(String.self, forKey: "object")
        self.deleted = try values.decode(Bool.self, forKey: "deleted")
    }

    public func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: StringCodingKey.self)
        try values.encode(id, forKey: "id")
        try values.encode(object, forKey: "object")
        try values.encode(deleted, forKey: "deleted")
    }
}
