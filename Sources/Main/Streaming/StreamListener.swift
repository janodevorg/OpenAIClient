public struct StreamListener<T> {
    public var onMessage: ([T]) throws -> Void
    public var onStreamClosed: () -> Void
}
