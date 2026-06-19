import AppKit
import CoreImage
import CoreImage.CIFilterBuiltins

enum DominantColor {
    /// Returns the average color of `image` as an NSColor, boosting luminance if too dark
    /// for use as a karaoke-wipe accent against a dark backdrop.
    static func extract(from image: NSImage) -> NSColor {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return .systemGray
        }
        let ciImage = CIImage(cgImage: cgImage)
        let extent = ciImage.extent
        let extentVec = CIVector(x: extent.origin.x,
                                 y: extent.origin.y,
                                 z: extent.size.width,
                                 w: extent.size.height)
        let filter = CIFilter.areaAverage()
        filter.inputImage = ciImage
        filter.setValue(extentVec, forKey: kCIInputExtentKey)
        guard let output = filter.outputImage else { return .systemGray }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [.workingColorSpace: NSNull()])
        context.render(output,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                       format: .RGBA8,
                       colorSpace: CGColorSpaceCreateDeviceRGB())

        var r = CGFloat(bitmap[0]) / 255.0
        var g = CGFloat(bitmap[1]) / 255.0
        var b = CGFloat(bitmap[2]) / 255.0

        let luminance = 0.299*r + 0.587*g + 0.114*b
        if luminance < 0.45 {
            let boost = 0.55 / max(luminance, 0.05)
            r = min(1.0, r * boost)
            g = min(1.0, g * boost)
            b = min(1.0, b * boost)
        }
        return NSColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}
