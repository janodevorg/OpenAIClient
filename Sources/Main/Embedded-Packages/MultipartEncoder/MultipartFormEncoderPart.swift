import Foundation

struct MultipartFormEncoderPart {
    let data: Data?
    let dataFileURL: URL?
    let encoding: String
    let filename: String?
    let length: Int64
    let name: String
    let type: String

    static func text(name: String, text: String) -> MultipartFormEncoderPart? {
        let data = Data(text.utf8)
        return MultipartFormEncoderPart(name: name, type: "text/plain; charset=utf-8", encoding: "8bit", data: data)
    }

    init(name: String, type: String, encoding: String, data: Data, filename: String? = nil) {
        self.dataFileURL = nil
        self.name = name
        self.type = type
        self.encoding = encoding
        self.data = data
        self.filename = filename
        self.length = Int64(data.count)
    }

    init(name: String, type: String, encoding: String, dataFileURL: URL, filename: String? = nil) throws {
        self.data = nil
        self.name = name
        self.type = type
        self.encoding = encoding
        self.dataFileURL = dataFileURL
        self.filename = filename
        guard let length = FileManager.default.sizeOfFile(at: dataFileURL) else {
            throw MultipartFormEncodingError.fileLengthUnknown
        }
        self.length = length
    }

    var isBinary: Bool {
        encoding == "binary"
    }
}
