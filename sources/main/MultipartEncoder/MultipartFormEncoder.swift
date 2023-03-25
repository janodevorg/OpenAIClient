import Foundation
import Logger

final class MultipartFormEncoder {
    private let log: Logger

    private let boundary: String

    private var parts: [MultipartFormEncoderPart] = []

    private var contentTypeMultipartFormData: String {
        "multipart/form-data; boundary=\"\(boundary)\""
    }

    private let TWO_HYPHENS = "--"
    private let LINE_END = "\r\n"
    private let LINE_END_DATA = "\r\n".data(using: .utf8)! // swiftlint:disable:this force_unwrapping

    private class func generateArbitraryBoundaryString() -> String {
        let usascii = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<16).compactMap { _ in usascii.randomElement() })
    }

    init(log: Logger, customBoundary: String? = nil) {
        self.log = log
        self.boundary = customBoundary ?? Self.generateArbitraryBoundaryString()
    }

    func addPart(_ part: MultipartFormEncoderPart) {
        assert(part.data != nil || part.dataFileURL != nil)
        parts.append(part)
    }

    func addText(name: String, text: String, filename: String? = nil) throws {
        guard let data = text.data(using: .utf8) else {
            throw MultipartFormEncodingError.invalidText(text)
        }
        let type = "text/plain; charset=utf-8"
        let part = MultipartFormEncoderPart(name: name, type: type, encoding: "8bit", data: data, filename: filename)
        parts.append(part)
    }

    func addBinary(name: String, contentType: String, data: Data, filename: String? = nil) {
        let part = MultipartFormEncoderPart(name: name, type: contentType, encoding: "binary", data: data, filename: filename)
        parts.append(part)
    }

    func addBinary(name: String, contentType: String, fileURL: URL, filename: String? = nil) throws {
        assert(FileManager.default.fileExists(atPath: fileURL.path))
        let part = try MultipartFormEncoderPart(name: name, type: contentType, encoding: "binary", dataFileURL: fileURL, filename: filename)
        parts.append(part)
    }

    func encodeToMemory() throws -> MultipartEncodingInMemory {
        let stream = OutputStream.toMemory()
        stream.open()
        do {
            try encode(to: stream)
            stream.close()
            guard let data = stream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data else {
                throw MultipartFormEncodingError.internalError
            }
            return MultipartEncodingInMemory(contentType: contentTypeMultipartFormData, contentLength: Int64(data.count), body: data)
        } catch {
            stream.close()
            throw error
        }
    }

    func encodeToDisk(path: String) throws -> MultipartEncodingOnDisk {
        guard let stream = OutputStream(toFileAtPath: path, append: false) else {
            throw MultipartFormEncodingError.invalidPath(path)
        }
        stream.open()
        do {
            try encode(to: stream)
            stream.close()
            let fileURL = URL(fileURLWithPath: path)
            guard let length = FileManager.default.sizeOfFile(at: fileURL) else {
                throw MultipartFormEncodingError.fileLengthUnknown
            }
            return MultipartEncodingOnDisk(contentType: contentTypeMultipartFormData, contentLength: length, bodyFileURL: fileURL)
        } catch {
            stream.close()
            _ = try? FileManager.default.removeItem(atPath: path)
            throw error
        }
    }

    // MARK: - Private methods

    private func encode(to stream: OutputStream) throws {
        for part in parts {
            try writeHeader(part, to: stream)
            try writeBody(part, to: stream)
        }
        try writeFooter(to: stream)
    }

    private func writeHeader(_ part: MultipartFormEncoderPart, to stream: OutputStream) throws {
        let disposition: String
        if let filename = part.filename {
            disposition = "Content-Disposition: form-data; name=\"\(part.name)\"; filename=\"\(filename)\""
        } else {
            disposition = "Content-Disposition: form-data; name=\"\(part.name)\""
        }
        let header = [
            "\(TWO_HYPHENS)\(boundary)",
            disposition,
            "Content-Length: \(part.length)",
            "Content-Type: \(part.type)",
            "" // ends with a newline
        ].joined(separator: LINE_END)
        try writeString(header, to: stream)
        try writeData(LINE_END_DATA, to: stream)
    }

    private func writeBody(_ part: MultipartFormEncoderPart, to stream: OutputStream) throws {
        if let data = part.data {
            try writeData(data, to: stream)
        } else if let fileURL = part.dataFileURL {
            try writeFile(fileURL, to: stream)
        } else {
            throw MultipartFormEncodingError.invalidPart(part)
        }
        try writeData(LINE_END_DATA, to: stream)
    }

    private func writeFooter(to stream: OutputStream) throws {
        let footer = "\(TWO_HYPHENS)\(boundary)\(TWO_HYPHENS)\(LINE_END)"
        try writeString(footer, to: stream)
    }

    private func writeString(_ string: String, to stream: OutputStream) throws {
        guard let data = string.data(using: .utf8) else {
            throw MultipartFormEncodingError.invalidText(string)
        }
        try writeData(data, to: stream)
    }

    private func writeData(_ data: Data, to stream: OutputStream) throws {
        guard !data.isEmpty else {
            log.warn("Ignoring request to write 0 bytes of data to stream \(stream)")
            return
        }

        try data.withUnsafeBytes { dataBytes in
            guard let buffer: UnsafePointer<UInt8> = dataBytes.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw MultipartFormEncodingError.streamError
            }
            let written = stream.write(buffer, maxLength: data.count)
            if written < 0 {
                throw MultipartFormEncodingError.streamError
            }
        }
    }

    private func writeFile(_ url: URL, to stream: OutputStream) throws {
        guard let inStream = InputStream(fileAtPath: url.path) else {
            throw MultipartFormEncodingError.streamError
        }
        let bufferSize = 128 * 1_024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        inStream.open()

        defer {
            buffer.deallocate()
            inStream.close()
        }

        while inStream.hasBytesAvailable {
            let bytesRead = inStream.read(buffer, maxLength: bufferSize)
            if bytesRead > 0 {
                let bytesWritten = stream.write(buffer, maxLength: bytesRead)
                if bytesWritten < 0 {
                    throw MultipartFormEncodingError.streamError
                }
            } else {
                throw MultipartFormEncodingError.streamError
            }
        }
    }
}
