//
//  EditItemSheet.swift
//  QuickHold
//
//  编辑卡片界面
//

import SwiftUI
import PhotosUI
import QuickHoldCore

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
    @State private var availableTags: [String] = []

    // 图片编辑相关 / Image editing related
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var newImageData: [ImageData] = []
    @State private var imagesToDelete: Set<UUID> = []

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
                } else if item.type == .image {
                    imageContentSection
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

                    // 已选择的标签
                    if !tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localizationManager.localizedString("items.tags.selected"))
                                .font(.caption)
                                .foregroundStyle(.secondary)

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
                        .padding(.vertical, 8)
                    }

                    // 可选择的标签（排除已选择的）
                    if !availableTags.isEmpty {
                        let unselectedTags = availableTags.filter { !tags.contains($0) }

                        if !unselectedTags.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(localizationManager.localizedString("items.tags.available"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                FlowLayout(spacing: 8) {
                                    ForEach(unselectedTags, id: \.self) { tag in
                                        Button {
                                            addExistingTag(tag)
                                        } label: {
                                            HStack(spacing: 4) {
                                                Text(tag)
                                                Image(systemName: "plus.circle.fill")
                                                    .font(.caption)
                                            }
                                            .font(.subheadline.weight(.medium))
                                            .foregroundStyle(.blue)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(
                                                Capsule()
                                                    .strokeBorder(Color.blue, lineWidth: 1.5)
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                } header: {
                    Text(localizationManager.localizedString("items.tags.section"))
                } footer: {
                    Text(localizationManager.localizedString("items.tags.hint"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
            .task {
                await loadAvailableTags()
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

        // 添加到可用标签列表
        if !availableTags.contains(trimmed) {
            availableTags.append(trimmed)
            availableTags.sort()
        }
    }

    private func addExistingTag(_ tag: String) {
        guard !tags.contains(tag) else { return }
        tags.append(tag)
    }

    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }

    private func loadAvailableTags() async {
        do {
            let items = try await itemService.fetchAllItems()
            let tagSet = Set(items.flatMap { $0.tags })
            await MainActor.run {
                availableTags = Array(tagSet).sorted()
            }
        } catch {
            print("Error loading available tags: \(error)")
        }
    }

    // MARK: - Image Content Section

    private var imageContentSection: some View {
        Section {
            // 添加新图片按钮
            PhotosPicker(selection: $selectedImages, maxSelectionCount: 10, matching: .images) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                    Text(localizationManager.localizedString("items.images.select"))
                    Spacer()
                    if !newImageData.isEmpty {
                        Text("+\(newImageData.count)")
                            .foregroundStyle(.green)
                    }
                }
            }
            .onChange(of: selectedImages) { _, newItems in
                Task { await loadImages(from: newItems) }
            }

            // 显示现有图片和新添加的图片
            if let existingImages = item.images, !existingImages.isEmpty || !newImageData.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // 现有图片
                        ForEach(existingImages.filter { !imagesToDelete.contains($0.id) }) { image in
                            if let thumbnailData = image.thumbnailData,
                               let uiImage = UIImage(data: thumbnailData) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                    Button {
                                        imagesToDelete.insert(image.id)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.white, .red)
                                    }
                                    .offset(x: 8, y: -8)
                                }
                            }
                        }

                        // 新添加的图片
                        ForEach(newImageData.indices, id: \.self) { index in
                            if let uiImage = UIImage(data: newImageData[index].data) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                                    Button {
                                        newImageData.remove(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.white, .red)
                                    }
                                    .offset(x: 8, y: -8)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        } header: {
            Text(localizationManager.localizedString("items.images.section"))
        } footer: {
            Text(localizationManager.localizedString("items.images.limit"))
        }
    }

    private func loadImages(from items: [PhotosPickerItem]) async {
        newImageData.removeAll()

        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let fileName = "image_\(UUID().uuidString).jpg"
                newImageData.append(ImageData(data: data, fileName: fileName))
            }
        }
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

                // 删除标记的图片 / Delete marked images
                for imageId in imagesToDelete {
                    try await itemService.removeImage(id: imageId)
                }

                // 添加新图片 / Add new images
                if !newImageData.isEmpty {
                    try await itemService.addImages(to: item.id, images: newImageData)
                }
            }

            // 立即触发 iCloud 同步 / Trigger iCloud sync immediately
            CloudSyncMonitor.shared.manualSync()

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
