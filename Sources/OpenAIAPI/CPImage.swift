// swiftlint:disable file_types_order
#if os(iOS)
    import UIKit
    public typealias CPImage = UIImage
#elseif os(tvOS)
    import UIKit
    public typealias CPImage = UIImage
#elseif os(macOS)
    import AppKit
    public typealias CPImage = NSImage
#endif
// swiftlint:enable file_types_order

#if os(macOS)
public extension NSImage {
    func pngData() -> Data? {
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let imageRep = NSBitmapImageRep(cgImage: cgImage)
        imageRep.size = size // display size in points
        return imageRep.representation(using: .png, properties: [:])
    }
}
#endif
