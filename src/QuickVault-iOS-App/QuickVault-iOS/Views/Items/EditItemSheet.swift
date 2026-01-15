//
//  EditItemSheet.swift
//  QuickVault
//
//  编辑卡片界面
//

import SwiftUI
import QuickVaultCore

struct EditItemSheet: View {
    let item: ItemDTO
    let itemService: ItemService
    let onUpdate: () -> Void

    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var content: String
    @State private var tags: [String]
    @State private var tagInput = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(item: ItemDTO, itemService: ItemService, onUpdate: @escaping () -> Void) {
        self.item = item
        self.itemService = itemService
        self.onUpdate = onUpdate

        _title = State(initialValue: item.title)
        _content = State(initialValue: item.textContent ?? "")
        _tags = State(initialValue: item.tags)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(localizationManager.localizedString("items.info.title"), text: $title)
                        .font(.headline)
                } header: {
                    Text(localizationManager.localizedString("items.info.basic"))
                }

                if item.type == .text {
                    Section {
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .font(.body)
                            .lineSpacing(4)
                            .autocorrectionDisabled()
                    } header: {
                        Text(localizationManager.localizedString("items.content"))
                    }
                }

                Section {
                    // 标签输入
                    HStack {
                        TextField(localizationManager.localizedString("items.tags.placeholder"), text: $tagInput)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onSubmit {
                                addTag()
                            }

                        if !tagInput.isEmpty {
                            Button(localizationManager.localizedString("items.tags.add")) {
                                addTag()
                            }
                        }
                    }

                    // 标签列表
                    if !tags.isEmpty {
                        FlowLayout(spacing: 8) {
                            ForEach(tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)

                                    Button {
                                        removeTag(tag)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                }
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                            }
                        }
                    }
                } header: {
                    Text(localizationManager.localizedString("items.tags.section"))
                } footer: {
                    if tags.isEmpty {
                        Text(localizationManager.localizedString("items.tags.hint"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(item.type == .text ?
                           localizationManager.localizedString("items.type.text") :
                           localizationManager.localizedString("items.type.image"))
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.layoutDirection, localizationManager.layoutDirection)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.localizedString("common.cancel")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(localizationManager.localizedString("common.save")) {
                        Task { await saveChanges() }
                    }
                    .disabled(title.isEmpty || isLoading)
                }
            }
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .alert(localizationManager.localizedString("common.error"), isPresented: .constant(errorMessage != nil)) {
                Button(localizationManager.localizedString("common.ok")) {
                    errorMessage = nil
                }
            } message: {
                if let error = errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !tags.contains(trimmed) else {
            tagInput = ""
            return
        }
        
        tags.append(trimmed)
        tagInput = ""
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func saveChanges() async {
        guard !title.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            if item.type == .text {
                _ = try await itemService.updateTextItem(
                    id: item.id,
                    title: title,
                    content: content,
                    tags: tags
                )
            } else {
                _ = try await itemService.updateImageItem(
                    id: item.id,
                    title: title,
                    tags: tags
                )
            }
            
            onUpdate()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Helper Views

fileprivate struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.replacingUnspecifiedDimensions().width, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var frames: [CGRect] = []
        var size: CGSize = .zero
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth, currentX > 0 {
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
