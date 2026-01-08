import AppKit
import Carbon.HIToolbox
import Combine
import QuickVaultCore

final class MenuBarManager: NSObject, NSMenuDelegate {
  private let authService: AuthenticationService
  private let cardService: CardService
  private let menu = NSMenu()
  private var statusItem: NSStatusItem
  private var cancellables = Set<AnyCancellable>()
  private var hotKeyRef: EventHotKeyRef?
  private var hotKeyHandlerRef: EventHandlerRef?
  private var cardEditorWindowController: CardEditorWindowController?

  init(authService: AuthenticationService, cardService: CardService) {
    self.authService = authService
    self.cardService = cardService
    self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    super.init()

    menu.delegate = self
    statusItem.menu = menu
    statusItem.button?.toolTip = "QuickVault"

    updateIcon(for: authService.authenticationState)
    bindAuthState()
    registerGlobalHotKey()
    refreshMenu()
  }

  deinit {
    if let hotKeyRef {
      UnregisterEventHotKey(hotKeyRef)
    }
    if let hotKeyHandlerRef {
      RemoveEventHandler(hotKeyHandlerRef)
    }
  }

  func menuWillOpen(_ menu: NSMenu) {
    refreshMenu()
  }

  private func bindAuthState() {
    authService.authenticationStatePublisher
      .receive(on: RunLoop.main)
      .sink { [weak self] state in
        self?.updateIcon(for: state)
        self?.refreshMenu()
      }
      .store(in: &cancellables)
  }

  private func updateIcon(for state: AuthenticationState) {
    let icon: NSImage
    switch state {
    case .unlocked:
      icon = MenuBarIconView.renderImage(isLocked: false)
    case .locked, .setupRequired:
      icon = MenuBarIconView.renderImage(isLocked: true)
    }

    icon.isTemplate = true
    statusItem.button?.image = icon
  }

  private func refreshMenu() {
    switch authService.authenticationState {
    case .locked, .setupRequired:
      Task { @MainActor in
        buildLockedMenu()
      }
    case .unlocked:
      loadAndBuildMenu()
    }
  }

  private func loadAndBuildMenu() {
    Task { [weak self] in
      guard let self else { return }
      do {
        let cards = try await cardService.fetchAllCards()
        await MainActor.run {
          self.buildMenu(with: cards)
        }
      } catch {
        await MainActor.run {
          self.buildErrorMenu(message: "Failed to load cards")
        }
      }
    }
  }

  @MainActor
  private func buildLockedMenu() {
    menu.removeAllItems()

    let lockedItem = NSMenuItem(title: "Locked", action: nil, keyEquivalent: "")
    lockedItem.isEnabled = false
    menu.addItem(lockedItem)

    menu.addItem(.separator())

    let newCardItem = makeMenuItem(
      title: "New Card",
      image: NSImage(systemSymbolName: "plus", accessibilityDescription: "New Card"),
      action: #selector(newCard)
    )
    newCardItem.isEnabled = false
    menu.addItem(newCardItem)

    menu.addItem(makeMenuItem(
      title: "Open Dashboard",
      image: IconProvider.dashboardIcon,
      action: #selector(openDashboard)))

    menu.addItem(makeMenuItem(
      title: "Settings",
      image: IconProvider.settingsIcon,
      action: #selector(openSettings)))

    menu.addItem(.separator())
    menu.addItem(makeMenuItem(title: "Quit QuickVault", action: #selector(quitApp), keyEquivalent: "q"))
  }

  @MainActor
  private func buildErrorMenu(message: String) {
    menu.removeAllItems()

    let errorItem = NSMenuItem(title: message, action: nil, keyEquivalent: "")
    errorItem.isEnabled = false
    menu.addItem(errorItem)

    menu.addItem(.separator())
    menu.addItem(makeMenuItem(title: "Quit QuickVault", action: #selector(quitApp), keyEquivalent: "q"))
  }

  @MainActor
  private func buildMenu(with cards: [CardDTO]) {
    menu.removeAllItems()

    menu.addItem(makeMenuItem(
      title: "Open Dashboard",
      image: IconProvider.dashboardIcon,
      action: #selector(openDashboard)))

    menu.addItem(makeMenuItem(
      title: "New Card",
      image: NSImage(systemSymbolName: "plus", accessibilityDescription: "New Card"),
      action: #selector(newCard)))

    menu.addItem(.separator())

    let grouped = Dictionary(grouping: cards) { $0.group.lowercased() }
    let groupOrder = ["personal", "company"]
    let extraGroups = grouped.keys
      .filter { !groupOrder.contains($0) }
      .sorted()

    let orderedGroups = groupOrder + extraGroups
    let hasCards = !cards.isEmpty

    if !hasCards {
      let emptyItem = NSMenuItem(title: "No cards yet", action: nil, keyEquivalent: "")
      emptyItem.isEnabled = false
      menu.addItem(emptyItem)
    } else {
      for groupKey in orderedGroups {
        let groupCards = grouped[groupKey] ?? []
        let groupTitle = displayName(for: groupKey)
        let groupItem = NSMenuItem(title: groupTitle, action: nil, keyEquivalent: "")
        let groupMenu = NSMenu()

        if groupCards.isEmpty {
          let emptyGroupItem = NSMenuItem(title: "No cards", action: nil, keyEquivalent: "")
          emptyGroupItem.isEnabled = false
          groupMenu.addItem(emptyGroupItem)
        } else {
          for card in groupCards {
            let cardItem = NSMenuItem(title: card.title, action: nil, keyEquivalent: "")
            cardItem.submenu = buildCardMenu(for: card)
            groupMenu.addItem(cardItem)
          }
        }

        groupItem.submenu = groupMenu
        menu.addItem(groupItem)
      }
    }

    menu.addItem(.separator())

    let lockItem = makeMenuItem(title: "Lock", action: #selector(lockApp))
    lockItem.isEnabled = !authService.isLocked
    menu.addItem(lockItem)

    menu.addItem(makeMenuItem(
      title: "Settings",
      image: IconProvider.settingsIcon,
      action: #selector(openSettings)))

    menu.addItem(.separator())
    menu.addItem(makeMenuItem(title: "Quit QuickVault", action: #selector(quitApp), keyEquivalent: "q"))
  }

  @MainActor
  private func buildCardMenu(for card: CardDTO) -> NSMenu {
    let cardMenu = NSMenu()
    let isLocked = authService.isLocked

    let editItem = makeMenuItem(
      title: "Edit Card",
      image: NSImage(systemSymbolName: "pencil", accessibilityDescription: "Edit Card"),
      action: #selector(editCard(_:))
    )
    editItem.representedObject = card
    editItem.isEnabled = !isLocked
    cardMenu.addItem(editItem)

    let pinTitle = card.isPinned ? "Unpin" : "Pin"
    let pinItem = makeMenuItem(
      title: pinTitle,
      image: NSImage(systemSymbolName: "pin.fill", accessibilityDescription: pinTitle),
      action: #selector(togglePin(_:))
    )
    pinItem.representedObject = MenuCardPayload(id: card.id, title: card.title)
    pinItem.isEnabled = !isLocked
    cardMenu.addItem(pinItem)

    cardMenu.addItem(.separator())

    let copyCardItem = makeMenuItem(title: "Copy Card", action: #selector(copyItem(_:)))
    copyCardItem.representedObject = MenuCopyPayload(text: formattedCopyText(for: card))
    copyCardItem.isEnabled = !isLocked
    cardMenu.addItem(copyCardItem)

    cardMenu.addItem(.separator())

    if card.isPinned {
      let pinnedItem = NSMenuItem(title: "Pinned", action: nil, keyEquivalent: "")
      pinnedItem.image = NSImage(systemSymbolName: "pin.fill", accessibilityDescription: "Pinned")
      pinnedItem.isEnabled = false
      cardMenu.addItem(pinnedItem)
    }

    if !card.tags.isEmpty {
      let tagsValue = card.tags.joined(separator: ", ")
      let tagsItem = NSMenuItem(title: "Tags: \(tagsValue)", action: nil, keyEquivalent: "")
      tagsItem.image = NSImage(systemSymbolName: "tag", accessibilityDescription: "Tags")
      tagsItem.isEnabled = false
      cardMenu.addItem(tagsItem)
    }

    if card.isPinned || !card.tags.isEmpty {
      cardMenu.addItem(.separator())
    }

    if card.fields.isEmpty {
      let emptyItem = NSMenuItem(title: "No fields", action: nil, keyEquivalent: "")
      emptyItem.isEnabled = false
      cardMenu.addItem(emptyItem)
    } else {
      for field in card.fields {
        let fieldItem = makeMenuItem(title: "Copy \(field.label)", action: #selector(copyItem(_:)))
        fieldItem.representedObject = MenuCopyPayload(text: field.value)
        fieldItem.isEnabled = !isLocked && field.isCopyable
        cardMenu.addItem(fieldItem)
      }
    }

    let deleteItem = makeMenuItem(
      title: "Delete Card",
      image: NSImage(systemSymbolName: "trash", accessibilityDescription: "Delete Card"),
      action: #selector(deleteCard(_:))
    )
    deleteItem.representedObject = MenuCardPayload(id: card.id, title: card.title)
    deleteItem.isEnabled = !isLocked
    cardMenu.addItem(deleteItem)

    return cardMenu
  }

  private func displayName(for groupKey: String) -> String {
    if let group = CardGroup(rawValue: groupKey) {
      return group.displayName
    }
    if groupKey.isEmpty {
      return "Other"
    }
    return groupKey.capitalized
  }

  private func formattedCopyText(for card: CardDTO) -> String {
    guard let type = cardType(from: card.type) else {
      return fallbackCopyText(for: card)
    }

    let templateFields = CardTemplateHelper.fields(for: type)
    let values = fieldValues(for: card, templateFields: templateFields)
    if values.isEmpty {
      return fallbackCopyText(for: card)
    }

    return CardTemplateHelper.formatForCopy(type: type, fieldValues: values)
  }

  private func fallbackCopyText(for card: CardDTO) -> String {
    var lines: [String] = [card.title]
    for field in card.fields {
      lines.append("\(field.label): \(field.value)")
    }
    return lines.joined(separator: "\n")
  }

  private func fieldValues(for card: CardDTO, templateFields: [FieldDefinition]) -> [String: String] {
    var values: [String: String] = [:]
    for fieldDef in templateFields {
      if let match = card.fields.first(where: { $0.label == fieldDef.label }) {
        values[fieldDef.key] = match.value
      }
    }
    return values
  }

  private func cardType(from rawValue: String) -> CardType? {
    let cleaned = rawValue
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()
      .replacingOccurrences(of: " ", with: "")
      .replacingOccurrences(of: "_", with: "")
      .replacingOccurrences(of: "-", with: "")

    switch cleaned {
    case "general":
      return .general
    case "address":
      return .address
    case "invoice":
      return .invoice
    case "businesslicense":
      return .businessLicense
    case "idcard":
      return .idCard
    default:
      return CardType(rawValue: cleaned)
    }
  }

  private func registerGlobalHotKey() {
    let modifiers: UInt32 = UInt32(cmdKey | shiftKey)
    let keyCode: UInt32 = UInt32(kVK_ANSI_V)
    var hotKeyID = EventHotKeyID(signature: fourCharCode("QVLT"), id: 1)

    let status = RegisterEventHotKey(
      keyCode,
      modifiers,
      hotKeyID,
      GetApplicationEventTarget(),
      0,
      &hotKeyRef
    )

    guard status == noErr else {
      print("Failed to register global hotkey")
      return
    }

    var eventSpec = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard),
      eventKind: UInt32(kEventHotKeyPressed)
    )

    let handler: EventHandlerUPP = { _, _, userData in
      guard let userData else { return noErr }
      let manager = Unmanaged<MenuBarManager>.fromOpaque(userData).takeUnretainedValue()
      manager.handleHotKey()
      return noErr
    }

    InstallEventHandler(
      GetApplicationEventTarget(),
      handler,
      1,
      &eventSpec,
      Unmanaged.passUnretained(self).toOpaque(),
      &hotKeyHandlerRef
    )
  }

  private func handleHotKey() {
    openDashboard()
  }

  private func fourCharCode(_ string: String) -> FourCharCode {
    var result: UInt32 = 0
    for scalar in string.unicodeScalars {
      result = (result << 8) + scalar.value
    }
    return result
  }

  private func makeMenuItem(
    title: String,
    image: NSImage? = nil,
    action: Selector,
    keyEquivalent: String = ""
  ) -> NSMenuItem {
    let item = NSMenuItem(title: title, action: action, keyEquivalent: keyEquivalent)
    item.target = self
    if let image {
      image.isTemplate = true
      item.image = image
    }
    return item
  }

  @objc
  private func copyItem(_ sender: NSMenuItem) {
    guard let payload = sender.representedObject as? MenuCopyPayload else { return }
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(payload.text, forType: .string)
  }

  @objc
  private func openDashboard() {
    print("Open Dashboard requested")
  }

  @objc
  private func openSettings() {
    print("Open Settings requested")
  }

  @objc
  private func newCard() {
    guard !authService.isLocked else { return }
    presentCardEditor(mode: .new)
  }

  @objc
  private func editCard(_ sender: NSMenuItem) {
    guard !authService.isLocked else { return }
    guard let card = sender.representedObject as? CardDTO else { return }
    presentCardEditor(mode: .edit(card))
  }

  @objc
  private func togglePin(_ sender: NSMenuItem) {
    guard !authService.isLocked else { return }
    guard let payload = sender.representedObject as? MenuCardPayload else { return }

    Task { [weak self] in
      guard let self else { return }
      do {
        _ = try await self.cardService.togglePin(id: payload.id)
        await MainActor.run { self.refreshMenu() }
      } catch {
        await MainActor.run { self.buildErrorMenu(message: "Failed to update pin") }
      }
    }
  }

  @objc
  private func deleteCard(_ sender: NSMenuItem) {
    guard !authService.isLocked else { return }
    guard let payload = sender.representedObject as? MenuCardPayload else { return }

    let alert = NSAlert()
    alert.messageText = "Delete \"\(payload.title)\"?"
    alert.informativeText = "This action cannot be undone."
    alert.addButton(withTitle: "Delete")
    alert.addButton(withTitle: "Cancel")
    alert.alertStyle = .warning

    let response = alert.runModal()
    guard response == .alertFirstButtonReturn else { return }

    Task { [weak self] in
      guard let self else { return }
      do {
        try await self.cardService.deleteCard(id: payload.id)
        await MainActor.run { self.refreshMenu() }
      } catch {
        await MainActor.run { self.buildErrorMenu(message: "Failed to delete card") }
      }
    }
  }

  @objc
  private func lockApp() {
    authService.lock()
  }

  @objc
  private func quitApp() {
    NSApp.terminate(nil)
  }

  private func presentCardEditor(mode: CardEditorMode) {
    if let existingWindow = cardEditorWindowController {
      existingWindow.close()
      cardEditorWindowController = nil
    }

    let editorState = CardEditorState(mode: mode)

    let view = CardEditorView(
      state: editorState,
      onSave: { [weak self] submission in
        guard let self else { return }

        let templateFields = CardTemplateHelper.fields(for: submission.type)
        let fields = templateFields.enumerated().map { index, fieldDef in
          CardFieldDTO(
            id: UUID(),
            label: fieldDef.label,
            value: submission.fieldValues[fieldDef.key] ?? "",
            isCopyable: true,
            order: Int16(index)
          )
        }

        let card: CardDTO
        switch submission.mode {
        case .new:
          card = try await self.cardService.createCard(
            title: submission.title,
            group: submission.group,
            type: submission.type.rawValue,
            fields: fields,
            tags: submission.tags
          )
        case .edit(let existing):
          card = try await self.cardService.updateCard(
            id: existing.id,
            title: submission.title,
            group: submission.group,
            fields: fields,
            tags: submission.tags
          )
        }

        if card.isPinned != submission.isPinned {
          _ = try await self.cardService.togglePin(id: card.id)
        }

        await MainActor.run { self.refreshMenu() }
      },
      onCancel: { [weak self] in
        self?.cardEditorWindowController?.close()
      }
    )

    let title = editorState.isEdit ? "Edit Card" : "New Card"
    let windowController = CardEditorWindowController(
      rootView: view,
      title: title
    ) { [weak self] in
      self?.cardEditorWindowController = nil
    }

    cardEditorWindowController = windowController
    windowController.showWindow(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
}

final class MenuCopyPayload: NSObject {
  let text: String

  init(text: String) {
    self.text = text
  }
}

final class MenuCardPayload: NSObject {
  let id: UUID
  let title: String

  init(id: UUID, title: String) {
    self.id = id
    self.title = title
  }
}
