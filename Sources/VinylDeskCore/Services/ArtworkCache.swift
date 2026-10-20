import SwiftUI
import AppKit

public final class ArtworkCache: @unchecked Sendable {
    public static let shared = ArtworkCache()

    private let imageCache = NSCache<NSString, NSImage>()
    private var dominantColors = [String: Color]()
    private let lock = NSLock()

    private init() {
        // Cache up to ~50MB of artwork
        imageCache.totalCostLimit = 50 * 1024 * 1024
        imageCache.countLimit = 40
    }

    public func image(for trackId: String, data: Data?, maxDimension: CGFloat = 400) -> NSImage? {
        guard let data = data, !data.isEmpty else { return nil }

        let cacheKey = "\(trackId)_\(Int(maxDimension))" as NSString
        if let cached = imageCache.object(forKey: cacheKey) {
            return cached
        }

        guard let original = NSImage(data: data) else { return nil }

        // Downscale to target dimension to keep RAM footprint ultra-low
        let downscaled = downscale(image: original, maxDimension: maxDimension)
        let cost = Int(downscaled.size.width * downscaled.size.height * 4)
        imageCache.setObject(downscaled, forKey: cacheKey, cost: cost)
        return downscaled
    }

    public func dominantColor(for trackId: String, data: Data?) -> Color? {
        lock.lock()
        if let cached = dominantColors[trackId] {
            lock.unlock()
            return cached
        }
        lock.unlock()

        guard let data = data, let image = NSImage(data: data) else { return nil }
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }

        let context = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
        guard let ctx = context else { return nil }
        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        guard let pixelBuffer = ctx.data else { return nil }
        let pixel = pixelBuffer.bindMemory(to: UInt8.self, capacity: 4)
        let r = Double(pixel[0]) / 255.0
        let g = Double(pixel[1]) / 255.0
        let b = Double(pixel[2]) / 255.0
        let color = Color(red: r, green: g, blue: b)

        lock.lock()
        dominantColors[trackId] = color
        lock.unlock()
        return color
    }

    private func downscale(image: NSImage, maxDimension: CGFloat) -> NSImage {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image }

        let aspect = size.width / size.height
        var targetWidth: CGFloat
        var targetHeight: CGFloat

        if size.width > size.height {
            targetWidth = min(size.width, maxDimension)
            targetHeight = targetWidth / aspect
        } else {
            targetHeight = min(size.height, maxDimension)
            targetWidth = targetHeight * aspect
        }

        let targetSize = NSSize(width: ceil(targetWidth), height: ceil(targetHeight))
        let targetRect = NSRect(origin: .zero, size: targetSize)

        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        image.draw(in: targetRect, from: NSRect(origin: .zero, size: size), operation: .copy, fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }

    public func fetchRemoteArtwork(from urlString: String, completion: @escaping (Data?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            completion(data)
        }.resume()
    }
}
