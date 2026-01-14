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
                    TextField("标题", text: $title)
                        .font(.headline)
                } header: {
                    Text("标题 / Title")
                }
                
                if item.type == .text {
                    Section {
                        TextEditor(text: $content)
                            .frame(minHeight: 200)
                            .font(.body)
                            .lineSpacing(4)
                            .autocorrectionDisabled()
                    } header: {
                        Text("内容 / Content")
                    }
                }
                
                Section {
                    // 标签输入
                    HStack {
                        TextField("添加标签", text: $tagInput)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .onSubmit {
                                addTag()
                            }
                        
                        if !tagInput.isEmpty {
                            Button("添加") {
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
                    Text("标签 / Tags")
                } footer: {
                    if tags.isEmpty {
                        Text("标签帮助你快速找到卡片")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(item.type == .text ? "编辑文本卡片" : "编辑图片卡片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
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
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("好的") {
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
