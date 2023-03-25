import Foundation

public struct TranscriptionFile {
    public enum Format: String {
        case mp3, mp4, mpeg, mpga, m4a, wav, webm
    }
    public let filename: String
    public let data: Data
    public let format: Format
    public var contentType: String {
        switch format {
        case .mp3: return "audio/mp3"
        case .mp4, .m4a: return "audio/mp4"
        case .mpeg, .mpga: return "audio/mpeg"
        case .wav: return "audio/wav"
        case .webm: return "audio/webm"
        }
    }
    public init(filename: String, data: Data, format: Format) {
        self.filename = filename
        self.data = data
        self.format = format
    }
}
