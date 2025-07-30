public struct StreamListener<T: Sendable>: Sendable {
    public var onMessage: @Sendable ([T]) throws -> Void
    public var onStreamClosed: @Sendable () -> Void
}
