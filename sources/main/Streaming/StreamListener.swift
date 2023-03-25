public struct StreamListener<T> {
    public var onMessage: ([T]) throws -> Void
}
