import AppKit
import SwiftUI

final class CardEditorWindowController: NSWindowController, NSWindowDelegate {
  private let onClose: () -> Void

  init<V: View>(rootView: V, title: String, onClose: @escaping () -> Void) {
    self.onClose = onClose

    let hostingView = NSHostingView(rootView: rootView)
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 480, height: 640),
      styleMask: [.titled, .closable, .miniaturizable],
      backing: .buffered,
      defer: false
    )
    window.title = title
    window.isReleasedWhenClosed = false
    window.level = .floating
    window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
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
  }
}
