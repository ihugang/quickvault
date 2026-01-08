import AppKit
import SwiftUI
import QuickVaultCore

final class CardEditorWindowController: NSWindowController, NSWindowDelegate {
  private let onClose: () -> Void

  init<V: View>(rootView: V, title: String, onClose: @escaping () -> Void) {
    self.onClose = onClose

    let hostingView = NSHostingView(rootView: rootView)
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 680, height: 780),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
      backing: .buffered,
      defer: false
    )
    window.title = title
    window.isReleasedWhenClosed = false
    window.level = .floating
    window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
    
    // Modern appearance
    window.titlebarAppearsTransparent = false
    window.styleMask.insert(.fullSizeContentView)
    
    // Set minimum size
    window.minSize = NSSize(width: 640, height: 700)
    window.maxSize = NSSize(width: 900, height: 1200)
    
    window.center()
    window.contentView = hostingView

    super.init(window: window)
    window.delegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func windowWillClose(_ notification: Notification) {
    onClose()
  }

  override func showWindow(_ sender: Any?) {
    super.showWindow(sender)
    window?.makeKeyAndOrderFront(nil)
    window?.orderFrontRegardless()
    
    // Smooth fade-in animation
    window?.alphaValue = 0.0
    NSAnimationContext.runAnimationGroup { context in
      context.duration = 0.25
      window?.animator().alphaValue = 1.0
    }
  }
}
