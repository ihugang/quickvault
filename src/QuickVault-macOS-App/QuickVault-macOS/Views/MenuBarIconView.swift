import SwiftUI
import QuickVaultCore

struct MenuBarIconView: View {
  let isLocked: Bool

  var body: some View {
    menuBarIcon
  }

  @ViewBuilder
  var menuBarIcon: some View {
    ZStack(alignment: .bottomTrailing) {
      Image(systemName: "tray.full")
        .symbolRenderingMode(.monochrome)
      if isLocked {
        Image(systemName: "lock.fill")
          .symbolRenderingMode(.monochrome)
          .font(.system(size: 10, weight: .semibold))
          .padding(1)
          .background(Circle().strokeBorder(lineWidth: 1))
          .offset(x: 3, y: 3)
      }
    }
    .font(.system(size: 16, weight: .regular))
    .foregroundStyle(.primary)
    .frame(width: 18, height: 18, alignment: .center)
  }

  static func renderImage(isLocked: Bool) -> NSImage {
    let view = MenuBarIconView(isLocked: isLocked)
    let hostingView = NSHostingView(rootView: view)
    let size = NSSize(width: 18, height: 18)
    hostingView.frame = NSRect(origin: .zero, size: size)

    let rep: NSBitmapImageRep
    if let cached = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) {
      rep = cached
    } else if let created = NSBitmapImageRep(
      bitmapDataPlanes: nil,
      pixelsWide: Int(size.width),
      pixelsHigh: Int(size.height),
      bitsPerSample: 8,
      samplesPerPixel: 4,
      hasAlpha: true,
      isPlanar: false,
      colorSpaceName: .deviceRGB,
      bytesPerRow: 0,
      bitsPerPixel: 0
    ) {
      rep = created
    } else {
      return NSImage(size: size)
    }

    hostingView.cacheDisplay(in: hostingView.bounds, to: rep)

    let image = NSImage(size: size)
    image.addRepresentation(rep)
    return image
  }
}
