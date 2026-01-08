import UIKit

/// Watermark configuration / 水印配置
struct WatermarkStyle {
    let fontSize: CGFloat
    let opacity: CGFloat
    let angle: CGFloat
    let color: UIColor

    static let `default` = WatermarkStyle(
        fontSize: 30,
        opacity: 0.3,
        angle: -45,
        color: .gray
    )
}

/// Service for applying watermarks to images / 图片水印服务
protocol WatermarkService {
    /// Apply watermark to image / 应用水印到图片
    func applyWatermark(to image: UIImage, text: String, style: WatermarkStyle) -> UIImage?
}

/// iOS implementation of watermark service / iOS 水印服务实现
class WatermarkServiceImpl: WatermarkService {
    func applyWatermark(to image: UIImage, text: String, style: WatermarkStyle = .default) -> UIImage? {
        // Preserve image quality by using the original scale
        UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Draw original image
        image.draw(at: .zero)

        // Configure watermark text attributes
        let font = UIFont.boldSystemFont(ofSize: style.fontSize)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: style.color.withAlphaComponent(style.opacity)
        ]

        let textSize = (text as NSString).size(withAttributes: attributes)

        // Calculate diagonal dimension for tile coverage
        let diagonal = sqrt(pow(image.size.width, 2) + pow(image.size.height, 2))
        let spacing: CGFloat = 200
        let tilesNeeded = Int(ceil(diagonal / spacing))

        // Save context state
        context.saveGState()

        // Apply tiled watermark pattern
        for row in 0..<tilesNeeded {
            for col in 0..<tilesNeeded {
                let x = CGFloat(col) * spacing
                let y = CGFloat(row) * spacing

                context.saveGState()

                // Translate to watermark position
                context.translateBy(x: x, y: y)

                // Rotate context
                context.rotate(by: style.angle * .pi / 180)

                // Draw watermark text
                let drawPoint = CGPoint(x: -textSize.width / 2, y: -textSize.height / 2)
                (text as NSString).draw(at: drawPoint, withAttributes: attributes)

                context.restoreGState()
            }
        }

        context.restoreGState()

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
