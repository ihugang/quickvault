import UIKit

/// Image export options / 图片导出选项
struct ImageExportOptions {
    /// Maximum width in pixels (nil = no limit) / 最大宽度（像素）
    let maxWidth: CGFloat?

    /// Maximum height in pixels (nil = no limit) / 最大高度（像素）
    let maxHeight: CGFloat?

    /// Maximum file size in KB (nil = no limit) / 最大文件大小（KB）
    let maxFileSizeKB: Int?

    /// JPEG compression quality (0.0 - 1.0) / JPEG 压缩质量
    let jpegQuality: CGFloat

    /// Default options with no limits / 默认选项（无限制）
    static let `default` = ImageExportOptions(
        maxWidth: nil,
        maxHeight: nil,
        maxFileSizeKB: nil,
        jpegQuality: 0.9
    )

    /// Preset for common size limits / 常用尺寸限制预设
    static func preset(maxDimension: Int, maxSizeKB: Int) -> ImageExportOptions {
        ImageExportOptions(
            maxWidth: CGFloat(maxDimension),
            maxHeight: CGFloat(maxDimension),
            maxFileSizeKB: maxSizeKB,
            jpegQuality: 0.85
        )
    }
}

/// Watermark spacing mode / 水印行间距模式
/// Controls how densely watermarks are tiled based on number of rows
enum WatermarkSpacing: Int, CaseIterable, Identifiable {
    case dense = 9      // 密集 - 约9行
    case normal = 6     // 正常 - 约6行 (default)
    case sparse = 4     // 稀疏 - 约4行

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .dense: return NSLocalizedString("watermark.spacing.dense", comment: "")
        case .normal: return NSLocalizedString("watermark.spacing.normal", comment: "")
        case .sparse: return NSLocalizedString("watermark.spacing.sparse", comment: "")
        }
    }
    
    /// Get the number of rows for this spacing mode
    var rowCount: Int { rawValue }
}

/// Watermark configuration / 水印配置
struct WatermarkStyle {
    let fontSize: CGFloat
    let opacity: CGFloat
    let angle: CGFloat
    let color: UIColor
    let spacing: WatermarkSpacing  // 行间距倍数

    static let `default` = WatermarkStyle(
        fontSize: 30,
        opacity: 0.3,
        angle: -45,
        color: .gray,
        spacing: .normal
    )

    /// Create style from parameters / 从参数创建样式
    static func from(fontSize: CGFloat, opacity: CGFloat = 0.3, spacing: WatermarkSpacing = .normal) -> WatermarkStyle {
        WatermarkStyle(
            fontSize: fontSize,
            opacity: opacity,
            angle: -45,
            color: .gray,
            spacing: spacing
        )
    }
}

/// Service for applying watermarks to images / 图片水印服务
protocol WatermarkService {
    /// Apply watermark to image / 应用水印到图片
    func applyWatermark(to image: UIImage, text: String, style: WatermarkStyle) -> UIImage?
}

/// Image processing utilities / 图片处理工具
class ImageProcessor {
    /// Resize image to fit within max dimensions / 调整图片大小以适应最大尺寸
    static func resize(image: UIImage, maxWidth: CGFloat?, maxHeight: CGFloat?) -> UIImage {
        guard maxWidth != nil || maxHeight != nil else { return image }

        let size = image.size
        var newSize = size

        // Calculate scale to fit within constraints
        if let maxW = maxWidth, size.width > maxW {
            let scale = maxW / size.width
            newSize = CGSize(width: maxW, height: size.height * scale)
        }

        if let maxH = maxHeight, newSize.height > maxH {
            let scale = maxH / newSize.height
            newSize = CGSize(width: newSize.width * scale, height: maxH)
        }

        // If no resize needed, return original
        if newSize == size { return image }

        // Perform resize
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: newSize))

        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }

    /// Compress image to target file size / 压缩图片到目标文件大小
    static func compress(image: UIImage, maxSizeKB: Int, initialQuality: CGFloat = 0.9) -> Data? {
        let maxBytes = maxSizeKB * 1024
        var quality = initialQuality

        // Try initial compression
        guard var data = image.jpegData(compressionQuality: quality) else { return nil }

        // If already within size, return
        if data.count <= maxBytes {
            return data
        }

        // Binary search for optimal quality
        var minQuality: CGFloat = 0.0
        var maxQuality = quality

        for _ in 0..<8 { // Max 8 iterations
            quality = (minQuality + maxQuality) / 2
            guard let compressed = image.jpegData(compressionQuality: quality) else { break }
            data = compressed

            if data.count > maxBytes {
                maxQuality = quality
            } else if data.count < maxBytes * 95 / 100 { // Within 95% of target
                minQuality = quality
            } else {
                break // Close enough
            }
        }

        return data
    }

    /// Apply export options to image / 应用导出选项到图片
    static func process(image: UIImage, options: ImageExportOptions) -> Data? {
        // Step 1: Resize if needed
        let processedImage = resize(image: image, maxWidth: options.maxWidth, maxHeight: options.maxHeight)

        // Step 2: Compress to file size if specified
        if let maxSizeKB = options.maxFileSizeKB {
            return compress(image: processedImage, maxSizeKB: maxSizeKB, initialQuality: options.jpegQuality)
        }

        // Otherwise just apply quality
        return processedImage.jpegData(compressionQuality: options.jpegQuality)
    }
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

        // Calculate spacing based on desired row count and image diagonal
        // 使用对角线长度来计算覆盖范围
        let diagonal = sqrt(pow(image.size.width, 2) + pow(image.size.height, 2))
        
        // 根据目标行数计算垂直间距
        let targetRows = CGFloat(style.spacing.rowCount)
        let verticalSpacing = diagonal / targetRows
        
        // 水平间距 = 文字宽度 + 2em (2倍字体大小)
        let horizontalSpacing = textSize.width + (style.fontSize * 2)
        
        // 计算需要的瓦片数量
        let rowsNeeded = Int(ceil(diagonal / verticalSpacing)) + 2
        let colsNeeded = Int(ceil(diagonal / horizontalSpacing)) + 2

        // Save context state
        context.saveGState()

        // Apply tiled watermark pattern
        for row in 0..<rowsNeeded {
            for col in 0..<colsNeeded {
                let x = CGFloat(col) * horizontalSpacing
                let y = CGFloat(row) * verticalSpacing

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
