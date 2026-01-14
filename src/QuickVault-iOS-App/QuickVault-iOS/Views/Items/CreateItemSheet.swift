//
//  CreateItemSheet.swift
//  QuickVault
//
//  优雅的创建卡片视图
//

import SwiftUI
import PhotosUI
import QuickVaultCore

struct CreateItemSheet: View {
    let itemService: ItemService
    @Binding var selectedType: ItemType?
    let onCreate: () -> Void
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var textContent = ""
    @State private var tags: [String] = []
    @State private var tagInput = ""
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var imageData: [ImageData] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    // 类型选择
                    if selectedType == nil {
                        typeSelectionSection
                    } else {
                        // 基本信息
                        basicInfoSection
                        
                        // 内容区域
                        if selectedType == .text {
                            textContentSection
                        } else {
                            imageContentSection
                        }
                        
                        // 标签
                        tagsSection
                    }
                }
                
                if isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle(selectedType == nil ? localizationManager.localizedString("items.create.selecttype") : String(format: localizationManager.localizedString("items.create.title"), selectedType!.displayName))
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.layoutDirection, localizationManager.layoutDirection)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.localizedString("common.cancel")) {
                        dismiss()
                    }
                }
                
                if selectedType != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(localizationManager.localizedString("items.create.button")) {
                            Task { await createItem() }
                        }
                        .disabled(!canCreate)
                    }
                }
            }
        }
    }
    
    // MARK: - Type Selection
    
    private var typeSelectionSection: some View {
        Section {
            Button {
                withAnimation {
                    selectedType = .text
                }
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "doc.text")
                            .font(.title2)
                            .foregroundStyle(.blue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.localizedString("items.type.text"))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(localizationManager.localizedString("items.type.text.desc"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 8)
            }
            
            Button {
                withAnimation {
                    selectedType = .image
                }
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.purple.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.purple)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.localizedString("items.type.image"))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(localizationManager.localizedString("items.type.image.desc"))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text(localizationManager.localizedString("items.create.selecttype"))
        }
    }
    
    // MARK: - Basic Info
    
    private var basicInfoSection: some View {
        Section {
            TextField(localizationManager.localizedString("items.info.title"), text: $title)
        } header: {
            Text(localizationManager.localizedString("items.info.basic"))
        } footer: {
            Text(localizationManager.localizedString("items.info.title.hint"))
        }
    }
    
    // MARK: - Text Content
    
    private var textContentSection: some View {
        Section {
            TextEditor(text: $textContent)
                .frame(minHeight: 150)
                .font(.body)
                .lineSpacing(4)
                .autocorrectionDisabled()
        } header: {
            Text(localizationManager.localizedString("items.content"))
        } footer: {
            Text(String(format: localizationManager.localizedString("items.content.characters"), textContent.count))
        }
    }
    
    // MARK: - Image Content
    
    private var imageContentSection: some View {
        Section {
            PhotosPicker(selection: $selectedImages, maxSelectionCount: 10, matching: .images) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                    Text(localizationManager.localizedString("items.images.select"))
                    Spacer()
                    if !imageData.isEmpty {
                        Text(String(format: localizationManager.localizedString("items.images.count"), imageData.count))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onChange(of: selectedImages) { _, newItems in
                Task { await loadImages(from: newItems) }
            }
            
            if !imageData.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(imageData.indices, id: \.self) { index in
                            if let uiImage = UIImage(data: imageData[index].data) {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    
                                    Button {
                                        imageData.remove(at: index)
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
    
    // MARK: - Tags
    
    private var tagsSection: some View {
        Section {
            HStack {
                TextField(localizationManager.localizedString("items.tags.placeholder"), text: $tagInput)
                    .onSubmit {
                        addTag()
                    }
                
                if !tagInput.isEmpty {
                    Button(localizationManager.localizedString("items.tags.add")) {
                        addTag()
                    }
                }
            }
            
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
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                    }
                }
                .padding(.vertical, 8)
            }
        } header: {
            Text(localizationManager.localizedString("items.tags.section"))
        } footer: {
            Text(localizationManager.localizedString("items.tags.hint"))
        }
    }
    
    // MARK: - Loading Overlay
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.5)
                Text(localizationManager.localizedString("common.loading"))
                    .foregroundColor(.white)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
            )
        }
    }
    
    // MARK: - Helpers
    
    private var canCreate: Bool {
        guard !title.isEmpty else { return false }
        
        if selectedType == .text {
            return !textContent.isEmpty
        } else {
            return !imageData.isEmpty
        }
    }
    
    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        tagInput = ""
    }
    
    private func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
    
    private func loadImages(from items: [PhotosPickerItem]) async {
        imageData = []
        
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let fileName = item.itemIdentifier ?? UUID().uuidString
                imageData.append(ImageData(data: data, fileName: fileName + ".jpg"))
            }
        }
    }
    
    private func createItem() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            if selectedType == .text {
                _ = try await itemService.createTextItem(
                    title: title,
                    content: textContent,
                    tags: tags
                )
            } else {
                _ = try await itemService.createImageItem(
                    title: title,
                    images: imageData,
                    tags: tags
                )
            }
            
            onCreate()
            dismiss()
        } catch {
            print("Error creating item: \(error)")
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
