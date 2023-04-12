import Foundation

/**
 A type not defined in OpenAI OpenAPI that appears when an error is returned.
 To see this type show up, query "Angelina Jolie" and you’ll get an "invalid_request_error".
 */
public struct OpenAIError: Error, Codable, CustomStringConvertible {
    public struct Payload: Codable {
        public let code: String?
        public let message: String
        public let param: String?
        public let type: String // "server_error"

        public init(code: String?, message: String, param: String?, type: String) {
            self.code = code
            self.message = message
            self.param = param
            self.type = type
        }
    }
    
    public let error: Payload
    public init(error: Payload) {
        self.error = error
    }

    public var description: String {
        """
        code: \(error.code ?? "")
        message: \(error.message)
        param: \(error.param ?? "")
        type: \(error.type)
        """
    }
}

/**
 Errors thrown by this package.
 The client of this package must not receive any error other than those defined here.
 */
public enum APIError: Error, CustomDebugStringConvertible {
    /// Server returned HTTP error.
    case apiServerHTTPError(String?, httpCode: Int)

    /// Server returned a non HTTP response.
    case apiServerNonHTTPResponse

    /// Server returned OpenAI API error.
    case apiServerOpenAIError(OpenAIError, httpCode: Int)

    /// Client detected bad parameters before calling the edit endpoint.
    case apiClientBadRequestEditEndpoint

    /// Client unexpectedly found a non UTF-8 string object
    case apiClientEncodingErrorExpectedUTF8

    /// Client detected bad parameters before calling the variations endpoint.
    case apiClientBadRequestVariationsEndpoint

    /// Client found an error during the encoding of a value.
    case apiClientEncodingError(EncodingError)

    /// Client found an error during the decoding of a value.
    case apiClientDecodingError(DecodingError)

    /// Client tried to create an invalid URL.
    case apiClientInvalidURL

    /// Error thrown by a mock that doesn’t implement the data required
    case mockUnimplementedError
    
    /// Unexpected error.
    case unexpectedError(Error)

    // invalid_request_error
    // "Invalid input image - format must be in ['RGBA', 'LA', 'L'], got RGB."
    // Use imagemagick to convert both images: convert image.png PNG32:image_png32.png

    /// Human readable description for developers.
    /// For the frinal user you may want to define your own localization without relying on this variable.
    public var localizedDescription: String {
        switch self {
        case let .apiServerHTTPError(string, code):
            return "Server returned HTTP error \(code), message: \(string as Any)."

        case .apiServerNonHTTPResponse:
            return "Server returned a non HTTP response"

        case let .apiServerOpenAIError(openAIError, _):
            return openAIError.error.message

        case .apiClientBadRequestEditEndpoint:
            return "Sorry, images must be PNG, less than 4MB, and square. If there is no mask, base image must have transparency." // swiftlint:disable:this line_length

        case .apiClientBadRequestVariationsEndpoint:
            return "Sorry, image must be PNG, less than 4MB, and square."

        case .apiClientEncodingErrorExpectedUTF8:
            return "Client encoding error expected UTF-8"

        case .apiClientEncodingError:
            return "Client encoding error: an encodable object failed to encode."

        case .apiClientDecodingError:
            return "Client decoding error: expected valid JSON string."

        case .apiClientInvalidURL:
            return "Client error: invalid URL."

        case .mockUnimplementedError:
            return "Unknown internal error."
            
        case .unexpectedError:
            return "Unknown internal error."
        }
    }

    public var debugDescription: String {
        switch self {

        case let .apiServerOpenAIError(openAIError, httpCode):
            return "\(localizedDescription). HTTP code: \(httpCode). OpenAIError: \(openAIError)"

        case let .apiClientEncodingError(encodingError):
            return "\(localizedDescription). EncodingError: \(encodingError)"

        case let .apiClientDecodingError(decodingError):
            return "\(localizedDescription). DecodingError: \(decodingError)"

        default:
            return localizedDescription
        }
    }
}
