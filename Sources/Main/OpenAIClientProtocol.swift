import Foundation
import OpenAIAPI

public protocol OpenAIClientProtocol {
    /// True if credentials are not nil or empty.
    var hasValidCredentials: Bool { get }

    /**
     Sets credentials.
     - Parameter apiKey: API Key from https://platform.openai.com/account/api-keys
     - Parameter organizationId: Organization ID from https://platform.openai.com/account/org-settings
    */
    func configure(apiKey: String, organizationId: String) -> Self

    /// Runs an authenticated call to check if the credentials are accepted by the server.
    func tryAuthenticatedCall() async throws

    // MARK: - Models

    /**
     Lists the currently available models, and provides basic information about each one such as the owner and availability.
     The result includes models created by the user.
     - Returns: Basic information about all models.
     - Throws: APIError
    */
    func models() async throws -> ListModelsResponse

    /**
     Retrieves a model instance, providing basic information about the model such as the owner and permissioning.
     - Parameter id: The ID of the model to use for this request.
     - Returns: Basic information about the model.
     - Throws: APIError
    */
    func model(id: String) async throws -> Model

    // MARK: - Completions

    /**
     Given a prompt, the model will return one or more predicted completions, and can also return the probabilities of alternative tokens at each position.
     For the minimum amount of parameters send model and prompt:
     ```
     completions(request: .init(model: "gpt-3.5-turbo", prompt: "do you ever question the nature of your reality?")
     ```
     - Parameter request: Completion parameters. `isStream` parameter will be false regardless of the value.
     - Throws: APIError
     */
    func completions(request: CreateCompletionRequest) async throws -> CreateCompletionResponse

    /**
     Creates a **streaming** completion.
     - Parameters:
       - request: Completion parameters. `isStream` parameter will be true regardless of the value.
       - streamListener: A listener block receiving chunks of text.
     - Returns: Streaming control that lets you start/stop the streaming process.
     - Throws: APIError
     */
    func streamingCompletion(
        request: CreateCompletionRequest,
        streamListener: @escaping ([CompletionChunk]) throws -> Void
    ) throws -> StreamingClient
    
    /**
     Creates a **streaming** completion.
     - Parameters:
       - request: Completion parameters. `isStream` parameter will be true regardless of the value.
     - Returns: Stream.
     - Throws: APIError
     */
    func streamingCompletion(request: CreateCompletionRequest) throws -> AsyncStream<[CompletionChunk]>

    // MARK: - Chat

    /**
     Creates a completion for the chat message.
     - Parameters:
       - modelId: ID of the model to use. See the [model endpoint compatibility](https://platform.openai.com/docs/models/model-endpoint-compatibility) table for details on which models work with the Chat API.
       - conversation: Previous chat messages are re-send here to keep track of the conversation.
     - Returns: Chat completion for the provided parameters.
     - Throws: APIError
     */
    func chatCompletion(id: String, conversation: [ChatCompletionRequestMessage]) async throws -> CreateChatCompletionResponse

    /**
     Creates a **streaming** completion for the chat message.
     - Parameters:
       - streamListener: receives stream chunks.
       - modelId: ID of the model to use. See the [model endpoint compatibility](https://platform.openai.com/docs/models/model-endpoint-compatibility) table for details on which models work with the Chat API.
       - conversation: Previous chat messages are re-send here to keep track of the conversation.
     - Returns: Streaming control that lets you start/stop the streaming process.
     - Throws: APIError
     */
    func streamingChatCompletion(
        streamListener: @escaping ([ChatChunk]) throws -> Void,
        modelId: String,
        conversation: [ChatCompletionRequestMessage]
    ) throws -> StreamingClient

    /**
     Creates a **streaming** completion for the chat message.
     - Parameters:
       - modelId: ID of the model to use. See the [model endpoint compatibility](https://platform.openai.com/docs/models/model-endpoint-compatibility) table for details on which models work with the Chat API.
       - conversation: Previous chat messages are re-send here to keep track of the conversation.
     - Returns: Stream.
     - Throws: APIError
     */
    func streamingChatCompletion(
        modelId: String,
        conversation: [ChatCompletionRequestMessage]
    ) throws -> AsyncStream<[ChatChunk]>
    
    // MARK: - Edit

    /// Given a prompt and an instruction, the model will return an edited version of the prompt.
    /// - Throws: APIError
    func edit(request: CreateEditRequest) async throws -> CreateEditResponse

    // MARK: - Images

    /// Creates an image given a prompt.
    /// - Throws: APIError
    func image(request: CreateImageRequest) async throws -> ImagesResponse

    /// Returns a version of the first image where the area indicated by the mask has been edited following the prompt instructions.
    /// - Throws: APIError
    func imageEdit(prompt: String, image: CPImage, mask: CPImage?) async throws -> ImagesResponse

    /**
     Creates a variation of a given image.
     - Parameters:
       - image: The image to use as the basis for the variation(s). Must be a valid PNG file, less than 4MB, and square.
       - numberOfImages: The number of images to generate. Must be between 1 and 10.
       - size: The size of the generated images. Must be one of 256x256, 512x512, or 1024x1024. Defaults to 1024x1024.
       - responseFormat: The format in which the generated images are returned. Must be one of `url` or `b64_json`.
       - userId: A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse. [Learn more](https://platform.openai.com/docs/guides/safety-best-practices/end-user-ids).
     - Returns: Variation(s) of the given image.
     - Throws: APIError
    */
    func imageVariations(
        image: CPImage,
        numberOfImages: Int,
        size: VariationsSize,
        responseFormat: VariationsFormat,
        userId: String?
    ) async throws -> ImagesResponse

    // MARK: - Embeddings
    
    /// Creates an embedding vector representing the input text.
    /// - Throws: APIError
    func createEmbedding(request: CreateEmbeddingRequest) async throws -> CreateEmbeddingResponse

    // MARK: - Audio

    /**
     Transcribes audio into the input language.
     - Parameters:
       - file: Binary data for a file with format mp3, mp4, mpeg, mpga, m4a, wav, or webm.
       - model: ID of the model to use. Only `whisper-1` is currently available.
       - prompt: An optional text to guide the model's style or continue a previous audio segment. The prompt should match the audio language.
       - responseFormat: The format of the transcript output, in one of these options: json, text, srt, verbose_json, or vtt.
       - temperature: The sampling temperature, between 0 and 1. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. If set to 0, the model will use log probability to automatically increase the temperature until certain thresholds are hit.
       - language: The language of the input audio. Supplying the input language in ISO-639-1 format will improve accuracy and latency.
     - Returns: Transcription text
     - Throws: APIError
     */
    func createTranscription( // swiftlint:disable:this function_parameter_count
        file: TranscriptionFile,
        language: ISO6391?,
        model: String,
        prompt: String?,
        temperature: Double?,
        responseFormat: TranscriptionFormat
    ) async throws -> CreateTranscriptionResponse

    /**
     Translates audio into into English.
     - Parameters:
       - file: Binary data for a file with format mp3, mp4, mpeg, mpga, m4a, wav, or webm.
       - model: ID of the model to use. Only `whisper-1` is currently available.
       - prompt: An optional text to guide the model's style or continue a previous audio segment. The [prompt](https://platform.openai.com/docs/guides/speech-to-text/prompting) should be in English.
       - responseFormat: The format of the transcript output, in one of these options: json, text, srt, verbose_json, or vtt.
       - temperature: The sampling temperature, between 0 and 1. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic. If set to 0, the model will use [log probability](https://en.wikipedia.org/wiki/Log_probability) to automatically increase the temperature until certain thresholds are hit.
       - language: The language of the input audio. Supplying the input language in ISO-639-1 format will improve accuracy and latency.
     - Returns: Translated text
     - Throws: APIError
     */
    func createTranslation(
        file: TranscriptionFile,
        model: String,
        prompt: String?,
        temperature: Double?,
        responseFormat: TranscriptionFormat
    ) async throws -> CreateTranscriptionResponse

    // MARK: - Files

    /// Returns a list of files that belong to the user's organization.
    /// - Throws: APIError
    func files() async throws -> ListFilesResponse

    /**
     Upload a file that contains document(s) to be used across various endpoints/features. Currently, the size of all the files uploaded by
     one organization can be up to 1 GB. Please contact us if you need to increase the storage limit.
     - Parameters:
       - file: Name of the JSON Lines file to be uploaded. If the purpose is set to "fine-tune", each line is a JSON record with "prompt"
               and "completion" fields representing your training examples.
       - purpose: The intended purpose of the uploaded documents. Use "fine-tune" for Fine-tuning. This allows us to validate the format of
                  the uploaded file.
     - Returns: Metadata of the file created.
     - Throws: APIError
     */
    func uploadFile(fileContent: String, filename: String, purpose: String) async throws -> OpenAIFile

    /**
     Delete a file.
     - Parameter id: The ID of the file to use for this request
     - Returns: Result from deleting the file.
     - Throws: APIError
     */
    func deleteFile(id: String) async throws -> DeleteFileResponse

    /**
     Returns information about a specific file.
     - Parameter id: The ID of the file to use for this request
     - Returns: Information about a file.
     - Throws: APIError
     */
    func retrieveFileInformation(id: String) async throws -> RetrieveFileResponse

    /**
     Returns the contents of the specified file
     - Parameter file_id: The ID of the file to use for this request
     - Throws: APIError
     */
    func retrieveFileContent(id: String) async throws -> String

    // MARK: - Fine-tunes
    
    /**
     Creates a job that fine-tunes a specified model from a given dataset.
     Response includes details of the enqueued job including job status and the name of the fine-tuned models once complete.
     - Parameter fineTuneRequest: fine tune request
     - Throws: APIError
     */
    func createFineTune(fineTuneRequest: CreateFineTuneRequest) async throws -> FineTune

    /**
     List your organization's fine-tuning jobs.
     - Note: This endpoint returns historical data about jobs executed. If you are looking for user models see models() instead.
     - Throws: APIError
    */
    func listFineTunes() async throws -> ListFineTunesResponse

    /**
     Gets info about the fine-tune job.
     - Parameter id: The ID of the fine-tune job.
     - Throws: APIError
     */
    func retrieveFineTune(id: String) async throws -> FineTune

    /**
     Immediately cancel a fine-tune job.
     - Parameter fine_tune_id: The ID of the fine-tune job to cancel
     - Throws: APIError
     */
    func cancelFineTune(id: String) async throws -> FineTune

    /**
     Get fine-grained status updates for a fine-tune job.
     - Parameter fine_tune_id: The ID of the fine-tune job to get events for.
     - Throws: APIError
     */
    func listFineTuneEvents(id: String) async throws -> ListFineTuneEventsResponse

    /**
     Get fine-grained status updates for a fine-tune job.
     - Parameter id: The ID of the fine-tune job to get events for.
     - Returns: Streaming control that lets you start/stop the streaming process.
     - Throws: APIError
     */
    func streamingListFineTuneEvents(
        id: String,
        streamListener: @escaping ([FineTuneEvent]) throws -> Void
    ) async throws -> StreamingClient

    /**
     Get fine-grained status updates for a fine-tune job.
     - Parameter fine_tune_id: The ID of the fine-tune job to get events for.
     - Returns: Stream
     - Throws: APIError
     */
    func streamingListFineTuneEvents(id: String) throws -> AsyncStream<[FineTuneEvent]>
    
    /**
     Delete a fine-tuned model. You must have the Owner role in your organization.

     Be aware: when you list fine-tunes you are getting a list of historical processes for models that may have already been deleted.
     Therefore you may get 'not found' errors when attempting to delete models take from that listing.

     - Parameter id: The ID of the model to delete.
     - Throws: APIError
     */
    func deleteFineTuneModel(id: String) async throws -> DeleteModelResponse

    // MARK: - Moderation

    /// Returns moderation information about the given input.
    /// - Throws: APIError
    func moderation(input: String, modelId: String) async throws -> CreateModerationResponse

    /**
     Lists the currently available (non-finetuned) models, and provides basic information about each one such as the owner and availability.
     - Note: The Engines endpoints are deprecated. Please use their replacement, Models, instead.
     - Throws: APIError
    */
    func engines() async throws -> ListEnginesResponse

    /**
     Lists the currently available (non-finetuned) models, and provides basic information about each one such as the owner and availability.
     - Note: The Engines endpoints are deprecated. Please use their replacement, Models, instead.
     - Parameter id: The ID of the engine to use for this request
     - Throws: APIError
    */
    func engine(id: String) async throws -> Engine
}
