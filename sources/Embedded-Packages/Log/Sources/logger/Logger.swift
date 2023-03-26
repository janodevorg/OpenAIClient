/// Logging protocol.
protocol Logger
{
    /// This label may appear as prefix of the message depending on the implementation.
    var label: String { get }

    /// The threshold below which messages are ignored.
    var threshold: Level { get }

    /// Actually output the log message to an external system.
    var send: (String) -> Void { get }

    /// Serialize the logged object to a string before sending it.
    func serialize<T>(_ object: T,
                      level: Level,
                      file: String,
                      function: String,
                      line: UInt) -> String

    /// Verbose messages intended for debugging or tracing code execution.
    func trace<T>(_ message: @autoclosure @escaping () -> T,
                  file: String,
                  function: String,
                  line: UInt)

    /// Messages intended for debugging or tracing code execution.
    func debug<T>(_ message: @autoclosure @escaping () -> T,
                  file: String,
                  function: String,
                  line: UInt)

    /// Messages providing general information.
    func info<T>(_ message: @autoclosure @escaping () -> T,
                 file: String,
                 function: String,
                 line: UInt)

    /// Messages indicating potential issues or non critical errors.
    func warn<T>(_ message: @autoclosure @escaping () -> T,
                 file: String,
                 function: String,
                 line: UInt)

    /// Messages indicating a malfunction that requires developer attention.
    func error<T>(_ message: @autoclosure @escaping () -> T,
                  file: String,
                  function: String,
                  line: UInt)
}
