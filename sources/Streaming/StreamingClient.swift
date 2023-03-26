import Foundation

public final class StreamingClient {
    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
    }
    private let authHeaders: [String: String]
    private let log: Logger
    private let url: URL
    private var eventSource: EventSource

    init(url: URL, authHeaders: [String: String], body: Data?, method: HTTPMethod, eventHandler: EventHandler, log: Logger) {
        self.authHeaders = authHeaders
        self.log = log
        self.url = url
        let eventSourceConfig = {
            var config = EventSource.Config(
                handler: eventHandler,
                url: url
            )
            config.method = method.rawValue
            config.headers = {
                var headers = authHeaders
                headers["Content-Type"] = "application/json"
                return headers
            }()
            if let body {
                config.body = body
            }
            config.reconnectTime = 1.0
            config.maxReconnectTime = 30.0
            config.backoffResetThreshold = 60.0
            config.idleTimeout = 300.0
            config.connectionErrorHandler = { error in
                log.error("connectionErrorHandler is shutting down connection. Error: \(error)")
                return .shutdown
            }
            return config
        }()
        self.eventSource = EventSource(config: eventSourceConfig, log: log)
    }

    deinit {
        stop()
    }

    public var state: ReadyState {
        eventSource.state
    }

    public func start() {
        eventSource.start()
    }

    public func stop() {
        eventSource.stop()
    }
}
