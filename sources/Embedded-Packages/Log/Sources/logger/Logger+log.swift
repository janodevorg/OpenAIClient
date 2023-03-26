/// Partial implementation that ignores logging calls when compiled for release.
/// Look at PrintLogger for an example of a concrete implementation.
extension Logger {
    private func log<T>(_ objectClosure: @escaping () -> T,
                        level: Level,
                        file: String,
                        function: String,
                        line: UInt) {
        guard level >= threshold  else { return }
        send(serialize(objectClosure(), level: level, file: file, function: function, line: line))
    }

    func trace<T>(_ message: @autoclosure @escaping () -> T,
                  file: String = #fileID,
                  function: String = #function,
                  line: UInt = #line) {
        #if DEBUG
        log(message, level: .trace, file: file, function: function, line: line)
        #endif
    }

    func debug<T>(_ message: @autoclosure @escaping () -> T,
                  file: String = #fileID,
                  function: String = #function,
                  line: UInt = #line) {
        #if DEBUG
        log(message, level: .debug, file: file, function: function, line: line)
        #endif
    }

    func info<T>(_ message: @autoclosure @escaping () -> T,
                 file: String = #fileID,
                 function: String = #function,
                 line: UInt = #line) {
        #if DEBUG
        log(message, level: .info, file: file, function: function, line: line)
        #endif
    }

    func warn<T>(_ message: @autoclosure @escaping () -> T,
                 file: String = #fileID,
                 function: String = #function,
                 line: UInt = #line) {
        #if DEBUG
        log(message, level: .warn, file: file, function: function, line: line)
        #endif
    }

    func error<T>(_ message: @autoclosure @escaping () -> T,
                  file: String = #fileID,
                  function: String = #function,
                  line: UInt = #line) {
        #if DEBUG
        log(message, level: .error, file: file, function: function, line: line)
        #endif
    }
}
