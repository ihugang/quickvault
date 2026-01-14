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
            .navigationTitle(selectedType == nil ? "选择类型" : "创建\(selectedType!.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                if selectedType != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("创建") {
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
                        Text("文本卡片")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("存储文本信息，便于快速分享")
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
                        Text("图片卡片")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("保存图片，支持添加水印分享")
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
            Text("选择卡片类型")
        }
    }
    
    // MARK: - Basic Info
    
    private var basicInfoSection: some View {
        Section {
            TextField("标题", text: $title)
        } header: {
            Text("基本信息")
        } footer: {
            Text("为卡片设置一个清晰的标题")
        }
    }
    
    // MARK: - Text Content
    
    private var textContentSection: some View {
        Section {
            TextEditor(text: $textContent)
                .frame(minHeight: 150)
        } header: {
            Text("内容")
        } footer: {
            Text("\(textContent.count) 字符")
        }
    }
    
    // MARK: - Image Content
    
    private var imageContentSection: some View {
        Section {
            PhotosPicker(selection: $selectedImages, maxSelectionCount: 10, matching: .images) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                    Text("选择图片")
                    Spacer()
                    if !imageData.isEmpty {
                        Text("\(imageData.count) 张")
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
            Text("图片")
        } footer: {
            Text("最多可选择 10 张图片")
        }
    }
    
    // MARK: - Tags
    
    private var tagsSection: some View {
        Section {
            HStack {
                TextField("添加标签", text: $tagInput)
                    .onSubmit {
                        addTag()
                    }
                
                if !tagInput.isEmpty {
                    Button("添加") {
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
            Text("标签")
        } footer: {
            Text("使用标签帮助分类和搜索")
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
                Text("创建中...")
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
