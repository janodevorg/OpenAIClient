import Foundation

extension FileManager {
    func sizeOfFile(at url: URL) -> Int64? {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
            guard let fileSize = resourceValues.fileSize else {
                throw MultipartFormEncodingError.fileLengthUnknown
            }
            return Int64(fileSize)
        } catch {
            #if DEBUG
            print("🚨 sizeOfFile at \(url): \(error.localizedDescription)")
            #endif
            return nil
        }
    }
}
