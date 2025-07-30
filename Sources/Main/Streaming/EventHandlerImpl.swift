import Foundation

final class EventHandlerImpl<T: Codable & Sendable>: EventHandler, @unchecked Sendable {
    struct Message: Sendable {
        let eventType: String
        let messageEvent: MessageEvent
    }
    private let log: Logger
    private let throttle: TimeInterval
    private let streamListener: StreamListener<T>

    init(
        log: Logger,
        shutdownToken: String,
        streamListener: StreamListener<T>,
        throttle: TimeInterval = 0.3
    ) {
        self.log = log
        self.shutdownToken = shutdownToken
        self.throttle = throttle
        self.streamListener = streamListener
    }

    private var buffer = [EventHandlerImpl.Message]()
    private var timer: Timer?
    private var isBarClosing = false

    private func sendBuffer() {
        guard !buffer.isEmpty else {
            return
        }
        var chunks = [T]()
        for message in buffer {
            if message.messageEvent.data == shutdownToken {
                continue
            }
            do {
                let data = Data(message.messageEvent.data.utf8)
                let newChunk: T = try JSONDecoder().decode(T.self, from: data)
                chunks.append(newChunk)
            } catch {
                log.error("Encoding failed for:\n\(message.messageEvent.data)")
                log.error(error)
            }
        }
        do {
            try streamListener.onMessage(chunks)
            buffer = []
        } catch {
            log.error(error)
        }
    }

    private func buffer(message: Message) {
        isBarClosing = isBarClosing || (message.messageEvent.data == shutdownToken)
        buffer.append(message)

        switch (timer, isBarClosing) {
        case (.none, true):
            // case where first message is a shutdown token
            sendBuffer()

        case (.some(let timer), true):
            // case where a timer is ongoing and we received a shutdown message
            timer.fire()
            timer.invalidate()

        case (.none, false):
            // case where there is no timer and we received a message → send first message immediately and schedule a timer
            self.sendBuffer()
            guard throttle > 0 else {
                // if throttle is 0 don’t start a timer. this causes all messages to be sent immediately
                return
            }
            let timer = Timer(timeInterval: throttle, repeats: true, block: { [weak self] _ in
                guard let self else { return }
                self.sendBuffer()
            })
            RunLoop.main.add(timer, forMode: .common)
            self.timer = timer

        case (.some, false):
            // case where a timer is ongoing and we received a message → nothing to do, wait for the timer to fire
            ()
        }
    }

    // MARK: - EventHandler

    let shutdownToken: String?

    func onMessage(eventType: String, messageEvent: MessageEvent) {
        log.trace("""
        SSE onMessage:
            eventType: \(eventType)
            messageEvent.data: \(messageEvent.data)
            messageEvent.lastEventId: \(messageEvent.lastEventId)
        """)
        buffer(message: Message(eventType: eventType, messageEvent: messageEvent))
    }

    func onOpened() {
        log.trace("SSE onOpened")
    }

    func onClosed() {
        log.trace("SSE onClosed")
        streamListener.onStreamClosed()
    }

    func onComment(comment: String) {
        log.trace("SSE comment: \(comment)")
    }

    func onError(error: Error) {
        log.error("SSE error: \(error)")
    }
}
