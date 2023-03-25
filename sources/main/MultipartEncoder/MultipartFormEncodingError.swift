import Foundation

enum MultipartFormEncodingError: Error {
    case invalidText(String)
    case invalidPath(String)
    case invalidPart(MultipartFormEncoderPart)
    case internalError
    case streamError
    case fileLengthUnknown
}
