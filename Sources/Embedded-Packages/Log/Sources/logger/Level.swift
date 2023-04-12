public enum Level: Int, Comparable
{
    /// Level for verbose messages intended for debugging or tracing code execution.
    case trace = 0
    /// Level for messages intended for debugging or tracing code execution.
    case debug = 1
    /// Level for messages providing general information.
    case info = 2
    /// Level for messages indicating potential issues or non critical errors.
    case warn = 3
    /// Level for messages indicating a malfunction that requires developer attention.
    case error = 4
    /// Level that ignores all messages
    case none = 5

    func icon() -> String {
        switch self {
        case .error: return "🚨 "
        case .info: return "ℹ️ "
        case .warn: return "⚠️ "
        default: return ""
        }
    }

    // MARK: - Comparable

    public static func == (lhs: Level, rhs: Level) -> Bool {
        lhs.rawValue == rhs.rawValue
    }
    public static func < (lhs: Level, rhs: Level) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
