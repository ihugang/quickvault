//
//  ItemDetailView.swift
//  QuickVault
//
//  优雅的详情视图
//

import SwiftUI
import QuickVaultCore

struct ItemDetailView: View {
    let item: ItemDTO
    let itemService: ItemService
    let onUpdate: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingShareSheet = false
    @State private var showingWatermarkSheet = false
    @State private var showingEditSheet = false
    @State private var shareContent: Any?
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 头部信息
                headerSection
                
                // 内容区域
                contentSection
                
                // 标签区域
                if !item.tags.isEmpty {
                    tagsSection
                }
                
                // 操作按钮
                actionsSection
                
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("编辑", systemImage: "pencil")
                    }
                    
                    Button {
                        Task { await togglePin() }
                    } label: {
                        Label(
                            item.isPinned ? "取消置顶" : "置顶",
                            systemImage: item.isPinned ? "pin.slash" : "pin"
                        )
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) {
                Task { await deleteItem() }
            }
        } message: {
            Text("此操作不可恢复")
        }
        .sheet(isPresented: $showingWatermarkSheet) {
            WatermarkConfigSheet(item: item, itemService: itemService) { content in
                shareContent = content
                showingShareSheet = true
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let content = shareContent {
                ShareSheet(activityItems: [content])
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditItemSheet(item: item, itemService: itemService, onUpdate: onUpdate)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // 类型图标
            ZStack {
                Circle()
                    .fill(item.type == .text ? Color.blue.opacity(0.1) : Color.purple.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: item.type.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(item.type == .text ? .blue : .purple)
            }
            
            // 标题
            Text(item.title)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            
            // 时间信息
            HStack(spacing: 16) {
                Label(
                    item.createdAt.formatted(date: .abbreviated, time: .omitted),
                    systemImage: "calendar"
                )
                
                if item.isPinned {
                    Label("已置顶", systemImage: "pin.fill")
                        .foregroundStyle(.orange)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Content Section
    
    @ViewBuilder
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if item.type == .text {
                textContentView
            } else {
                imageContentView
            }
        }
    }
    
    private var textContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.caption)
                Text("内容")
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            .foregroundStyle(.secondary)
            
            if let content = item.textContent {
                Text(content)
                    .font(.body)
                    .textSelection(.enabled)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.systemBackground))
                    )
            }
        }
    }
    
    private var imageContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo")
                    .font(.caption)
                Text("图片")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(item.images?.count ?? 0) 张")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.secondary)
            
            if let images = item.images, !images.isEmpty {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(images) { image in
                        ImageThumbnailView(image: image, itemService: itemService)
                    }
                }
            }
        }
    }
    
    // MARK: - Tags Section
    
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tag")
                    .font(.caption)
                Text("标签")
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.secondary)
            
            FlowLayout(spacing: 8) {
                ForEach(item.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.blue.opacity(0.1))
                        )
                }
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            if item.type == .text {
                Button {
                    Task { await shareText() }
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("分享文本")
                        Spacer()
                        if isLoading {
                            ProgressView()
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.blue)
                    )
                }
                .disabled(isLoading)
            } else {
                Button {
                    showingWatermarkSheet = true
                } label: {
                    HStack {
                        Image(systemName: "photo.badge.arrow.down")
                        Text("分享图片")
                        Spacer()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.purple)
                    )
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func togglePin() async {
        do {
            _ = try await itemService.togglePin(id: item.id)
            onUpdate()
            dismiss()
        } catch {
            print("Error toggling pin: \(error)")
        }
    }
    
    private func deleteItem() async {
        do {
            try await itemService.deleteItem(id: item.id)
            onUpdate()
            dismiss()
        } catch {
            print("Error deleting item: \(error)")
        }
    }
    
    private func shareText() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let text = try await itemService.getShareableText(id: item.id)
            shareContent = text
            showingShareSheet = true
        } catch {
            print("Error getting shareable text: \(error)")
        }
    }
}

// MARK: - Image Thumbnail View

struct ImageThumbnailView: View {
    let image: ImageDTO
    let itemService: ItemService
    
    @State private var showingFullImage = false
    @State private var fullImageData: Data?
    
    var body: some View {
        Button {
            Task { await loadFullImage() }
        } label: {
            Group {
                if let thumbnailData = image.thumbnailData,
                   let uiImage = UIImage(data: thumbnailData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Rectangle()
                            .fill(Color(.systemGray5))
                        ProgressView()
                    }
                }
            }
            .frame(height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .sheet(isPresented: $showingFullImage) {
            if let data = fullImageData, let uiImage = UIImage(data: data) {
                FullImageView(image: uiImage)
            }
        }
    }
    
    private func loadFullImage() async {
        do {
            fullImageData = try await itemService.getDecryptedImage(imageId: image.id)
            showingFullImage = true
        } catch {
            print("Error loading full image: \(error)")
        }
    }
}

// MARK: - Full Image View

struct FullImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZoomableScrollView {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            }
            .background(Color.black)
            .ignoresSafeArea()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Watermark Config Sheet

struct WatermarkConfigSheet: View {
    let item: ItemDTO
    let itemService: ItemService
    let onShare: ([UIImage]) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var useWatermark = false
    @State private var watermarkText = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("添加水印", isOn: $useWatermark)
                    
                    if useWatermark {
                        TextField("水印文字", text: $watermarkText)
                            .placeholder(when: watermarkText.isEmpty) {
                                Text("例如：仅供XX使用")
                                    .foregroundColor(.secondary)
                            }
                    }
                } header: {
                    Text("水印设置")
                } footer: {
                    Text("水印将显示在图片右下角")
                }
            }
            .navigationTitle("分享图片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("分享") {
                        Task { await shareImages() }
                    }
                    .disabled(isLoading || (useWatermark && watermarkText.isEmpty))
                }
            }
            .overlay {
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.3)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("准备中...")
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                        )
                    }
                }
            }
        }
    }
    
    private func shareImages() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let imagesData = try await itemService.getShareableImages(
                id: item.id,
                withWatermark: useWatermark,
                watermarkText: useWatermark ? watermarkText : nil
            )
            
            let uiImages = imagesData.compactMap { UIImage(data: $0) }
            
            dismiss()
            onShare(uiImages)
        } catch {
            print("Error getting shareable images: \(error)")
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
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

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

struct ZoomableScrollView<Content: View>: UIViewRepresentable {
    private var content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 4.0
        scrollView.minimumZoomScale = 1.0
        scrollView.bouncesZoom = true
        
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = true
        hostedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        hostedView.frame = scrollView.bounds
        scrollView.addSubview(hostedView)
        
        return scrollView
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(hostingController: UIHostingController(rootView: content))
    }
    
    func updateUIView(_ uiView: UIScrollView, context: Context) {
        context.coordinator.hostingController.rootView = content
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate {
        var hostingController: UIHostingController<Content>
        
        init(hostingController: UIHostingController<Content>) {
            self.hostingController = hostingController
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return hostingController.view
        }
    }
}
