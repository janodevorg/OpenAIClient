import Foundation

/// Message serializer.
struct Serializer
{
    private let label: String
    private let level: String
    private let message: String
    private let file: String
    private let function: String
    private let line: UInt

    private func filename(fileId: String) -> String {
        NSURL(fileURLWithPath: fileId).deletingPathExtension?.lastPathComponent ?? ""
    }

    init(label: String,
         level: String,
         message: String,
         file: String,
         function: String,
         line: UInt)
    {
        self.label = label
        self.level = level
        self.message = message
        self.file = file
        self.function = function
        self.line = line
    }

    func serialize() -> String {
        let label = label.components(separatedBy: ".").last ?? label
        let location = filename(fileId: file) + "." + function
        let prefix = "[\(label)] "
        var msg = "\(prefix)" + location.resizeString(newLength: UInt(40) - UInt(prefix.count))
        msg += ":"
        msg += "\(line)".padLeft(newLength: 3)
        msg += " · "
        msg += level + message
        return msg
    }
}
