import Foundation
import Get
import OpenAIAPI

/**
 Validates that the response code is in range [200,300).

 - Throws: APIError.apiServerOpenAIError Server errors returned by OpenAI.
 - Throws: APIError.apiServerHTTPError HTTP server error.
 */
private func validate(response: HTTPURLResponse, data: Data) throws {
    guard (200..<300).contains(response.statusCode) else {
        if let openAIError = try? JSONDecoder().decode(OpenAIError.self, from: data) {
            throw APIError.apiServerOpenAIError(openAIError, httpCode: response.statusCode)
        }
        if let string = String(data: data, encoding: .utf8) {
            throw APIError.apiServerHTTPError(string, httpCode: response.statusCode)
        }
        throw APIError.apiServerHTTPError(nil, httpCode: response.statusCode)
    }
}

private struct ThrowOnErrorDelegate: APIClientDelegate {
    private let log: Logger

    init(log: Logger) {
        self.log = log
    }

    func client(_ client: APIClient, validateResponse response: HTTPURLResponse, data: Data, task: URLSessionTask) throws {
        try validate(response: response, data: data)
    }
}

public struct OpenAIClient: OpenAIClientProtocol {
    private static let baseURL = URL(string: "https://api.openai.com/v1")! // swiftlint:disable:this force_unwrapping
    private let api: APIClient
    private let log: Logger

    /// Value of the Authorization Bearer token.
    private var apiKey: String?

    /// Value of the optional "OpenAI-Organization" header.
    private var organizationId: String?

    // Reused for each streaming request
    private var eventSource: EventSource?

    public init(log: Level = .debug) {
        let logger = DumpLogger(label: "OpenAIClient", threshold: log)
        self.log = logger
        self.api = APIClient(baseURL: OpenAIClient.baseURL) { conf in
            conf.delegate = ThrowOnErrorDelegate(log: logger)
        }
    }

    // MARK: - OpenAIClientProtocol

    public func configure(apiKey: String, organizationId: String) -> OpenAIClient {
        var client = self
        client.apiKey = apiKey
        client.organizationId = organizationId
        return client
    }

    public var hasValidCredentials: Bool {
        guard let apiKey = apiKey, let organizationId = organizationId else {
            return false
        }
        return !apiKey.isEmpty && !organizationId.isEmpty
    }
    
    public func tryAuthenticatedCall() async throws {
        _ = try await models()
    }

    // MARK: - Models

    public func models() async throws -> ListModelsResponse {
        var request = Paths.models.get
        request.headers = makeHeaders()
        return try await api.send(request).value
    }

    public func model(id: String) async throws -> Model {
        var request = Paths.models.model(id).get
        request.headers = makeHeaders()
        return try await api.send(request).value
    }

    // MARK: - Completion

    public func completions(request: CreateCompletionRequest) async throws -> CreateCompletionResponse {
        var completionRequest = request
        completionRequest.isStream = false
        var request = Paths.completions.post(completionRequest)
        request.headers = makeHeaders()
        return try await api.send(request).value
    }

    public func streamingCompletion(
        request: CreateCompletionRequest,
        streamListener: @escaping ([CompletionChunk]) throws -> Void
    ) throws -> StreamingClient {
        var completionRequest = request
        completionRequest.isStream = true
        let eventHandler = EventHandlerImpl(
            log: log,
            shutdownToken: "[DONE]",
            streamListener: StreamListener(onMessage: { try streamListener($0) }, onStreamClosed: {})
        )
        return StreamingClient(
            url: OpenAIClient.baseURL.appendingPathComponent("completions"),
            authHeaders: makeHeaders(),
            body: try encode(completionRequest),
            method: .post,
            eventHandler: eventHandler,
            log: log
        )
    }
    
    public func streamingCompletion(
        request: CreateCompletionRequest
    ) throws -> AsyncStream<[CompletionChunk]> {
        var completionRequest = request
        completionRequest.isStream = true
        let data = try encode(completionRequest)
        let url = OpenAIClient.baseURL.appendingPathComponent("completions")
        return try stream(url: url, method: .post, body: data)
    }

    // MARK: - Chat

    public func chatCompletion(id: String, conversation: [ChatCompletionRequestMessage]) async throws -> CreateChatCompletionResponse {
        let chatCompletionRequest = CreateChatCompletionRequest(model: id, messages: conversation)
        var request = Paths.chat.completions.post(chatCompletionRequest)
        request.headers = makeHeaders()
        return try await api.send(request).value
    }

    public func streamingChatCompletion(
        streamListener: @escaping ([ChatChunk]) throws -> Void,
        modelId: String,
        conversation: [ChatCompletionRequestMessage]
    ) throws -> StreamingClient {
        let chatCompletionRequest = CreateChatCompletionRequest(
            model: modelId,
            messages: conversation,
            isStream: true
        )
        let eventHandler = EventHandlerImpl(
            log: log,
            shutdownToken: "[DONE]",
            streamListener: StreamListener(onMessage: { try streamListener($0) }, onStreamClosed: {})
        )
        return StreamingClient(
            url: OpenAIClient.baseURL.appendingPathComponent("chat/completions"),
            authHeaders: makeHeaders(),
            body: try encode(chatCompletionRequest),
            method: .post,
            eventHandler: eventHandler,
            log: log
        )
    }
        
    public func streamingChatCompletion(
        modelId: String,
        conversation: [ChatCompletionRequestMessage]
    ) throws -> AsyncStream<[ChatChunk]> {
        let chatCompletionRequest = CreateChatCompletionRequest(
            model: modelId,
            messages: conversation,
            isStream: true
        )
        let data = try encode(chatCompletionRequest)
        let url = OpenAIClient.baseURL.appendingPathComponent("chat/completions")
        return try stream(url: url, method: .post, body: data)
    }

    // MARK: - Edit

    public func edit(request: CreateEditRequest) async throws -> CreateEditResponse {
        var request = Paths.edits.post(request)
        request.headers = makeHeaders()
        return try await api.send(request).value
    }

    // MARK: - Images

    public func image(request: CreateImageRequest) async throws -> ImagesResponse {
        var request = Paths.images.generations.post(request)
        request.headers = makeHeaders()
        return try await api.send(request).value
    }

    public func imageEdit(prompt: String, image: CPImage, mask: CPImage?) async throws -> ImagesResponse {
        guard let imageData = image.pngData(),
                imageData.count < 4_000_000,
                image.size.width == image.size.height else {
            throw APIError.apiClientBadRequestEditEndpoint
        }
        let endpointURL = OpenAIClient.baseURL.appendingPathComponent("images/edits")
        let multipartForm = MultipartFormEncoder(log: log)
        multipartForm.addBinary(name: "image", contentType: "image/png", data: imageData, filename: "image.png")
        if let mask = mask {
            guard let maskData = mask.pngData(),
                    maskData.count < 4_000_000,
                    mask.size.width == mask.size.height,
                    mask.size == image.size else {
                throw APIError.apiClientBadRequestEditEndpoint
            }
            multipartForm.addBinary(name: "mask", contentType: "image/png", data: maskData, filename: "mask.png")
        }
        try multipartForm.addText(name: "prompt", text: prompt)
        let codedMultipart = try multipartForm.encodeToMemory()
        return try await postRequestWithBody(endpoint: endpointURL, codedMultipart: codedMultipart)
    }
    
    public func imageVariations(
        image: CPImage,
        numberOfImages: Int = 5,
        size: VariationsSize = .size256x256,
        responseFormat: VariationsFormat = .url,
        userId: String? = nil
    ) async throws -> ImagesResponse {
        guard let imageData = image.pngData(), imageData.count < 4_000_000 else {
            throw APIError.apiClientBadRequestVariationsEndpoint
        }
        let endpointURL = OpenAIClient.baseURL.appendingPathComponent("images/variations")
        let multipartForm = MultipartFormEncoder(log: log)
        try multipartForm.addText(name: "n", text: "\(numberOfImages)")
        try multipartForm.addText(name: "size", text: size.rawValue)
        try multipartForm.addText(name: "response_format", text: responseFormat.rawValue)
        if let userId = userId {
            try multipartForm.addText(name: "user", text: userId)
        }
        multipartForm.addBinary(name: "image", contentType: "image/png", data: imageData, filename: "variations.png")
        let codedMultipart = try multipartForm.encodeToMemory()
        return try await postRequestWithBody(endpoint: endpointURL, codedMultipart: codedMultipart)
    }

    // MARK: - Embeddings

    public func createEmbedding(request: CreateEmbeddingRequest) async throws -> CreateEmbeddingResponse {
        var request = Paths.embeddings.post(request)
        request.headers = makeHeaders()
        return try await api.send(request).value
    }

    // MARK: - Audio

    public func createTranscription(
        file: TranscriptionFile,
        language: ISO6391?,
        model: String,
        prompt: String?,
        temperature: Double?,
        responseFormat: TranscriptionFormat = .json
    ) async throws -> CreateTranscriptionResponse {
        let path = Paths.audio.transcriptions.path
        let endpointURL = OpenAIClient.baseURL.appendingPathComponent(path)
        let multipartForm = MultipartFormEncoder(log: log)
        try multipartForm.addText(name: "model", text: model)
        if let prompt {
            try multipartForm.addText(name: "prompt", text: prompt)
        }
        try multipartForm.addText(name: "response_format", text: responseFormat.rawValue)
        if let temperature {
            try multipartForm.addText(name: "temperature", text: "\(temperature)")
        }
        if let language {
            try multipartForm.addText(name: "language", text: "\(language.rawValue)")
        }
        multipartForm.addBinary(name: "file", contentType: file.contentType, data: file.data, filename: file.filename)
        let codedMultipart = try multipartForm.encodeToMemory()
        return try await postRequestWithBody(endpoint: endpointURL, codedMultipart: codedMultipart)
    }

    public func createTranslation(
        file: TranscriptionFile,
        model: String,
        prompt: String?,
        temperature: Double?,
        responseFormat: TranscriptionFormat = .json
    ) async throws -> CreateTranscriptionResponse {
        let path = Paths.audio.translations.path
        let endpointURL = OpenAIClient.baseURL.appendingPathComponent(path)
        let multipartForm = MultipartFormEncoder(log: log)
        try multipartForm.addText(name: "model", text: model)
        if let prompt {
            try multipartForm.addText(name: "prompt", text: prompt)
        }
        try multipartForm.addText(name: "response_format", text: responseFormat.rawValue)
        if let temperature {
            try multipartForm.addText(name: "temperature", text: "\(temperature)")
        }
        multipartForm.addBinary(name: "file", contentType: file.contentType, data: file.data, filename: file.filename)
        let codedMultipart = try multipartForm.encodeToMemory()
        return try await postRequestWithBody(endpoint: endpointURL, codedMultipart: codedMultipart)
    }

    private func postRequestWithBody<T: Codable>(
        endpoint: URL,
        codedMultipart: MultipartEncodingInMemory
    ) async throws -> T {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = codedMultipart.body
        request.allHTTPHeaderFields = {
            var headers = makeHeaders()
            headers["Content-Type"] = codedMultipart.contentType
            headers["Content-Length"] = codedMultipart.contentLength.description
            return headers
        }()

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpUrlResponse = response as? HTTPURLResponse else {
            throw APIError.apiServerNonHTTPResponse
        }

        try validate(response: httpUrlResponse, data: data)

        do {
            return try JSONDecoder().decode(T.self, from: data) as T
        } catch {
            if let responseString = String(data: data, encoding: .utf8) {
                log.error("\n🚨Error: \(error)\n🚨 Response: \(response) \n🚨Response as String: \(responseString)")
            }
            throw error
        }
    }

    // MARK: - Files

    public func files() async throws -> ListFilesResponse {
        let url = OpenAIClient.baseURL.appendingPathComponent(Paths.files.path)
        var request = Request<ListFilesResponse>(url: url.absoluteString, id: "files")
        request.headers = makeHeaders()
        return try await api.send(request).value
    }

    public func uploadFile(fileContent: String, filename: String, purpose: String) async throws -> OpenAIFile {
        let path = Paths.files.path
        let endpointURL = OpenAIClient.baseURL.appendingPathComponent(path)
        let multipartForm = MultipartFormEncoder(log: log)
        try multipartForm.addText(name: "purpose", text: purpose)

        guard let data = fileContent.data(using: .utf8) else {
            throw APIError.apiClientEncodingErrorExpectedUTF8
        }

        multipartForm.addBinary(
            name: "file",
            contentType: "application/octet-stream",
            data: data,
            filename: filename
        )

        let codedMultipart = try multipartForm.encodeToMemory()
        return try await postRequestWithBody(endpoint: endpointURL, codedMultipart: codedMultipart)
    }

    public func deleteFile(id: String) async throws -> DeleteFileResponse {
        let url = OpenAIClient.baseURL.appendingPathComponent(Paths.files.path).appendingPathComponent(id)
        var request = Request<DeleteFileResponse>(method: .delete, url: url, id: "delete-\(id)")
        request.headers = makeHeaders()
        return try await api.send(request).value
    }

    public func retrieveFileInformation(id: String) async throws -> RetrieveFileResponse {
        let url = OpenAIClient.baseURL.appendingPathComponent(Paths.files.path).appendingPathComponent(id)
        var request = Request<RetrieveFileResponse>(method: .get, url: url, id: "get-\(id)")
        request.headers = makeHeaders()
        return try await api.send(request).value
    }

    public func retrieveFileContent(id: String) async throws -> String {
        let url = OpenAIClient.baseURL.appendingPathComponent(Paths.files.path)
            .appendingPathComponent(id)
            .appendingPathComponent("content")
        var request = Request<String>(method: .get, url: url, id: "content-\(id)")
        request.headers = makeHeaders()
        return try await api.send(request).value
    }

    // MARK: - Fine-tunes

    // Send at least CreateFineTuneRequest(trainingFile: fileId)
    public func createFineTune(fineTuneRequest: CreateFineTuneRequest) async throws -> FineTune {
        var request = Paths.fineTunes.post(fineTuneRequest)
        request.headers = makeHeaders()
        // note: extra 'FineTune' type in next line prevents compiler crash "misaligned pointer..."
        let finetune: FineTune = try await api.send(request).value
        return finetune
    }

    public func listFineTunes() async throws -> ListFineTunesResponse {
        var request = Paths.fineTunes.get
        request.headers = makeHeaders()
        return try await api.send(request).value
    }

    public func retrieveFineTune(id: String) async throws -> FineTune {
        var request = Paths.fineTunes.fineTuneID(id).get
        request.headers = makeHeaders()
        return try await api.send(request).value
    }

    public func cancelFineTune(id: String) async throws -> FineTune {
        var request = Paths.fineTunes.fineTuneID(id).cancel.post
        request.headers = makeHeaders()
        return try await api.send(request).value
    }

    public func listFineTuneEvents(id: String) async throws -> ListFineTuneEventsResponse {
        var request = Paths.fineTunes.fineTuneID(id).events.get(isStream: false)
        request.headers = makeHeaders()
        return try await api.send(request).value
    }

    public func streamingListFineTuneEvents(
        id: String,
        streamListener: @escaping ([FineTuneEvent]) throws -> Void
    ) async throws -> StreamingClient {
        let eventHandler = EventHandlerImpl(
            log: log,
            shutdownToken: "[DONE]",
            streamListener: StreamListener(onMessage: { try streamListener($0) }, onStreamClosed: {})
        )

        // using URLComponents because .appending(queryItems:) requires macos 13
        let url = OpenAIClient.baseURL.appendingPathComponent("fine-tunes/\(id)/events")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        let queryItem = URLQueryItem(name: "stream", value: "true")
        components?.queryItems = [queryItem]
        guard let streamingURL = components?.url else {
            throw APIError.apiClientInvalidURL
        }

        return StreamingClient(
            url: streamingURL,
            authHeaders: makeHeaders(),
            body: nil,
            method: .get,
            eventHandler: eventHandler,
            log: log
        )
    }
    
    public func streamingListFineTuneEvents(id: String) throws -> AsyncStream<[FineTuneEvent]> {
        // using URLComponents because .appending(queryItems:) requires macos 13
        let url = OpenAIClient.baseURL.appendingPathComponent("fine-tunes/\(id)/events")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        let queryItem = URLQueryItem(name: "stream", value: "true")
        components?.queryItems = [queryItem]
        guard let streamingURL = components?.url else {
            throw APIError.apiClientInvalidURL
        }
        
        return try stream(url: streamingURL, method: .get, body: nil)
    }

    public func deleteFineTuneModel(id: String) async throws -> DeleteModelResponse {
        var request = Paths.models.model(id).delete
        request.headers = makeHeaders()
        return try await api.send(request).value
    }

    // MARK: - Moderation

    public func moderation(input: String, modelId: String) async throws -> CreateModerationResponse {
        let createModerationRequest = CreateModerationRequest(
            input: CreateModerationRequest.Input.string(input),
            model: modelId
        )
        var request = Paths.moderations.post(createModerationRequest)
        request.headers = makeHeaders()
        return try await api.send(request).value
    }

    // MARK: - Engines

    @available(*, deprecated, message: "Deprecated")
    public func engines() async throws -> ListEnginesResponse {
        var request = Paths.engines.get
        request.headers = makeHeaders()
        return try await api.send(request).value
    }

    @available(*, deprecated, message: "Deprecated")
    public func engine(id: String) async throws -> Engine {
        var request = Paths.engines.engineID(id).get
        request.headers = makeHeaders()
        return try await api.send(request).value
    }
    
    // MARK: - Private
    
    /// Encode the given object.
    /// - Throws: APIError.apiClientEncodingError
    private func encode<T: Encodable>(_ encodable: T) throws -> Data {
        do {
            return try JSONEncoder().encode(encodable)
        } catch {
            if let encodingError = error as? EncodingError {
                throw APIError.apiClientEncodingError(encodingError)
            } else {
                throw APIError.unexpectedError(error)
            }
        }
    }
    
    private func makeHeaders() -> [String: String] {
        var headers = [String: String]()
        if let bearerKey = apiKey {
            headers["Authorization"] = "Bearer \(bearerKey)"
        }
        if let openAiOrgKey = organizationId {
            headers["OpenAI-Organization"] = openAiOrgKey
        }
        return headers
    }
    
    private func stream<T: Codable>(
        url: URL,
        method: StreamingClient.HTTPMethod,
        body: Data?
    ) throws -> AsyncStream<[T]> {
        AsyncStream([T].self) { continuation in
            let streamListener = StreamListener<T>(
                onMessage: { continuation.yield($0) },
                onStreamClosed: { continuation.finish() }
            )
            let eventHandler = EventHandlerImpl(
                log: log,
                shutdownToken: "[DONE]",
                streamListener: streamListener
            )
            let client = StreamingClient(
                url: url,
                authHeaders: makeHeaders(),
                body: body,
                method: method,
                eventHandler: eventHandler,
                log: log
            )
            
            let onTermination: (@Sendable (AsyncStream<[T]>.Continuation.Termination) -> Void)? = { [client] reason in
                self.log.debug("Stream terminated with reason: \(reason)")
                client.stop()
            }
            continuation.onTermination = onTermination
            client.start()
        }
    }
}
