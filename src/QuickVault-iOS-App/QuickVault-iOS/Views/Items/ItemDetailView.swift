//
//  ItemDetailView.swift
//  QuickVault
//
//  优雅的详情视图
//

import SwiftUI
import QuickVaultCore

// MARK: - Color Palette
private enum DetailPalette {
    // Primary - 深蓝色（安全与信任）
    static let primary = Color(red: 0.20, green: 0.40, blue: 0.70)       // #3366B3
    static let secondary = Color(red: 0.15, green: 0.65, blue: 0.60)     // #26A699 青绿色
    static let accent = Color(red: 0.95, green: 0.70, blue: 0.20)        // #F2B333 金色
    
    // Neutral
    static let canvas = Color(red: 0.965, green: 0.975, blue: 0.985)
    static let card = Color.white
    static let border = Color(red: 0.88, green: 0.90, blue: 0.92)        // #E0E5EB
}

struct ItemDetailView: View {
    let item: ItemDTO
    let itemService: ItemService
    let onUpdate: () -> Void
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingEditSheet = false
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
        .background(DetailPalette.canvas)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.white.opacity(0.94), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.light, for: .navigationBar)
        .tint(DetailPalette.primary)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label(localizationManager.localizedString("items.detail.edit"), systemImage: "pencil")
                    }
                    
                    Button {
                        Task { await togglePin() }
                    } label: {
                        Label(
                            localizationManager.localizedString(item.isPinned ? "items.detail.unpin" : "items.detail.pin"),
                            systemImage: item.isPinned ? "pin.slash" : "pin"
                        )
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label(localizationManager.localizedString("items.detail.delete"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                }
            }
        }
        .alert(localizationManager.localizedString("items.delete.title"), isPresented: $showingDeleteAlert) {
            Button(localizationManager.localizedString("common.cancel"), role: .cancel) { }
            Button(localizationManager.localizedString("items.detail.delete"), role: .destructive) {
                Task { await deleteItem() }
            }
        } message: {
            Text(localizationManager.localizedString("items.delete.message"))
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
                    .fill(item.type == .text ? Color.blue.opacity(0.12) : DetailPalette.primary.opacity(0.12))
                    .frame(width: 80, height: 80)
                
                Image(systemName: item.type.icon)
                    .font(.system(size: 36))
                    .foregroundStyle(item.type == .text ? .blue : DetailPalette.primary)
            }
            
            // 标题
            Text(item.title)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
            
            // 时间信息
            HStack(spacing: 16) {
                Label(
                    "\(localizationManager.localizedString("items.detail.created")) \(localizationManager.formatDate(item.createdAt, dateStyle: .medium))",
                    systemImage: "calendar"
                )
                
                if item.isPinned {
                    Label(localizationManager.localizedString("items.detail.pinned"), systemImage: "pin.fill")
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
                Text(localizationManager.localizedString("items.detail.content"))
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            .foregroundStyle(.secondary)
            
            if let content = item.textContent {
                Text(content)
                    .font(.body)
                    .lineSpacing(4)
                    .multilineTextAlignment(.leading)
                    .textSelection(.enabled)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                        .background(DetailPalette.card)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(DetailPalette.border, lineWidth: 1)
                    )
                        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
            }
        }
    }
    
    private var imageContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo")
                    .font(.caption)
                    .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 0.3))
                Text(localizationManager.localizedString("items.detail.images"))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(String(format: localizationManager.localizedString("items.detail.images.count"), item.images?.count ?? 0))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.secondary)
            
            if let images = item.images, !images.isEmpty {
                VStack(spacing: 12) {
                    ForEach(images) { image in
                        ImageThumbnailView(image: image, itemService: itemService, item: item)
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
                Text(localizationManager.localizedString("items.detail.tags"))
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.secondary)
            
            FlowLayout(spacing: 8) {
                ForEach(item.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(DetailPalette.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                            .fill(DetailPalette.primary.opacity(0.12))
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
                        Text(localizationManager.localizedString("items.detail.share.text"))
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
                            .fill(DetailPalette.primary)
                    )
                }
                .disabled(isLoading)
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
            await MainActor.run {
                showSystemShareSheet(items: [text])
            }
        } catch {
            print("Error getting shareable text: \(error)")
        }
    }
    
    private func showSystemShareSheet(items: [Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ [ItemDetailView] Cannot find root view controller")
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // iPad 需要设置 popover
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                       y: rootViewController.view.bounds.midY,
                                       width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // 找到最顶层的 presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        topController.present(activityVC, animated: true)
    }
}

// MARK: - Image Thumbnail View

// MARK: - Image Thumbnail View

struct ImageDataWrapper: Identifiable {
    let id = UUID()
    let data: Data
}

struct ImageThumbnailView: View {
    let image: ImageDTO
    let itemService: ItemService
    let item: ItemDTO
    
    @State private var imageDataToShow: ImageDataWrapper?
    @State private var displayImageData: Data?
    @State private var isLoading = true
    
    var body: some View {
        Button {
            Task { await loadFullImage() }
        } label: {
            Group {
                if isLoading {
                    ZStack {
                        Rectangle()
                            .fill(Color(.systemGray5))
                        ProgressView()
                    }
                    .frame(height: 200)
                } else if let data = displayImageData,
                          let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                } else {
                    ZStack {
                        Rectangle()
                            .fill(Color(.systemGray5))
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundStyle(Color(red: 0.2, green: 0.5, blue: 0.3).opacity(0.6))
                    }
                    .frame(height: 200)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .fullScreenCover(item: $imageDataToShow) { wrapper in
            if let uiImage = UIImage(data: wrapper.data) {
                FullImageView(image: uiImage, item: item, itemService: itemService)
                    .onAppear {
                        print("✅ [FullImageView] Displayed image from \(wrapper.data.count) bytes")
                    }
            } else {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.yellow)
                        Text("无法创建图片")
                            .foregroundStyle(.white)
                            .font(.headline)
                        Text("数据大小: \(wrapper.data.count) bytes")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                imageDataToShow = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white, .black.opacity(0.5))
                            }
                            .padding()
                        }
                        Spacer()
                    }
                }
                .onAppear {
                    print("❌ [FullImageView] Failed to create UIImage from \(wrapper.data.count) bytes")
                }
            }
        }
        .task {
            await loadDisplayImage()
        }
    }
    
    private func loadDisplayImage() async {
        print("🔍 [ImageThumbnailView] Loading display image: \(image.id)")
        do {
            displayImageData = try await itemService.getDecryptedImage(imageId: image.id)
            print("✅ [ImageThumbnailView] Display image loaded: \(displayImageData?.count ?? 0) bytes")
        } catch {
            print("❌ [ImageThumbnailView] Error loading display image: \(error)")
        }
        isLoading = false
    }
    
    private func loadFullImage() async {
        print("🔍 [ImageThumbnailView] Loading full image for viewing")
        
        // 优先使用已加载的displayImageData
        if let displayData = displayImageData {
            print("✅ [ImageThumbnailView] Using display image data: \(displayData.count) bytes")
            imageDataToShow = ImageDataWrapper(data: displayData)
        } else {
            print("🔍 [ImageThumbnailView] Loading fresh image data")
            do {
                let freshData = try await itemService.getDecryptedImage(imageId: image.id)
                print("✅ [ImageThumbnailView] Fresh image loaded: \(freshData.count) bytes")
                imageDataToShow = ImageDataWrapper(data: freshData)
            } catch {
                print("❌ [ImageThumbnailView] Error loading image: \(error)")
            }
        }
        
        if imageDataToShow != nil {
            print("✅ [ImageThumbnailView] imageDataToShow is set, fullScreenCover should open")
        } else {
            print("❌ [ImageThumbnailView] imageDataToShow is still nil")
        }
    }
}

// MARK: - Full Image View

struct FullImageView: View {
    let image: UIImage
    let item: ItemDTO
    let itemService: ItemService
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    @State private var showControls = false
    @State private var useWatermark = false
    @State private var watermarkText = ""
    @State private var watermarkFontSize: CGFloat = 30
    @State private var watermarkSpacing: WatermarkSpacing = .normal
    @State private var watermarkOpacity: CGFloat = 0.3
    @State private var isSharing = false
    @State private var previewImage: UIImage?
    @State private var shareAllImages = true
    
    init(image: UIImage, item: ItemDTO, itemService: ItemService) {
        self.image = image
        self.item = item
        self.itemService = itemService
        print("✅ [FullImageView] Initialized with image size: \(image.size)")
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 背景：水印模式时用较亮的背景，查看模式时用黑色
                (showControls ? Color(.systemBackground) : Color.black)
                    .ignoresSafeArea()
                
                // 图片区域
                VStack(spacing: 0) {
                    if showControls {
                        // 水印模式：图片置顶
                        ZoomableScrollView {
                            Image(uiImage: previewImage ?? image)
                                .resizable()
                                .scaledToFit()
                        }
                        .frame(maxHeight: geometry.size.height * 0.5) // 占上半部分
                        .id(previewImage?.hashValue ?? image.hashValue)
                        
                        Spacer()
                    } else {
                        // 查看模式：图片居中
                        ZoomableScrollView {
                            Image(uiImage: previewImage ?? image)
                                .resizable()
                                .scaledToFit()
                        }
                        .id(previewImage?.hashValue ?? image.hashValue)
                    }
                }
                .onAppear {
                    print("✅ [FullImageView] View appeared")
                }
                .animation(.easeInOut(duration: 0.3), value: showControls)
            
            VStack(spacing: 0) {
                // 顶部按钮栏
                HStack {
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .black.opacity(0.5))
                    }
                    .padding()
                }
                
                Spacer()
                
                // 底部控制面板（可展开）
                if showControls {
                    watermarkControlPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 8)
                }
                
                // 底部按钮栏（始终显示）
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showControls.toggle()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: showControls ? "chevron.down" : "slider.horizontal.3")
                            Text(localizationManager.localizedString(showControls ? "watermark.collapse" : "watermark.settings"))
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.7))
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    Button {
                        Task { await shareImages() }
                    } label: {
                        HStack(spacing: 6) {
                            if isSharing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                                Text(localizationManager.localizedString("watermark.share"))
                            }
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .clipShape(Capsule())
                    }
                    .disabled(isSharing)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            }
        }
    }
    
    private var watermarkControlPanel: some View {
        VStack(spacing: 16) {
            // 分享范围选择（仅多图时显示）
            if let images = item.images, images.count > 1 {
                VStack(alignment: .leading, spacing: 6) {
                    Text(localizationManager.localizedString("watermark.scope"))
                        .font(.subheadline)
                    Picker(localizationManager.localizedString("watermark.scope"), selection: $shareAllImages) {
                        Text(localizationManager.localizedString("watermark.scope.current")).tag(false)
                        Text(String(format: localizationManager.localizedString("watermark.scope.all"), images.count)).tag(true)
                    }
                    .pickerStyle(.segmented)
                }
            }
            
            // 水印开关
            Toggle(localizationManager.localizedString("watermark.add"), isOn: $useWatermark)
                .toggleStyle(.switch)
                .tint(DetailPalette.primary)
                .onChange(of: useWatermark) { _, _ in
                    isTextFieldFocused = false
                    updatePreview()
                }
            
            if useWatermark {
                // 水印文字
                TextField(localizationManager.localizedString("watermark.text"), text: $watermarkText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        isTextFieldFocused = false
                    }
                    .onChange(of: watermarkText) { _, _ in
                        updatePreview()
                    }
                
                // 字体大小
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(localizationManager.localizedString("watermark.fontsize"))
                        Spacer()
                        Text("\(Int(watermarkFontSize))")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    Slider(value: $watermarkFontSize, in: 20...80, step: 1)
                        .tint(DetailPalette.primary)
                        .onChange(of: watermarkFontSize) { _, _ in
                            isTextFieldFocused = false
                            updatePreview()
                        }
                }
                
                // 行间距
                VStack(alignment: .leading, spacing: 6) {
                    Text(localizationManager.localizedString("watermark.spacing"))
                        .font(.subheadline)
                    Picker(localizationManager.localizedString("watermark.spacing"), selection: $watermarkSpacing) {
                        ForEach(WatermarkSpacing.allCases) { spacing in
                            Text(localizationManager.localizedString("watermark.spacing.\(spacing.localizedKey)")).tag(spacing)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: watermarkSpacing) { _, _ in
                        isTextFieldFocused = false
                        updatePreview()
                    }
                }
                
                // 透明度
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(localizationManager.localizedString("watermark.opacity"))
                        Spacer()
                        Text("\(Int(watermarkOpacity * 100))%")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                    Slider(value: $watermarkOpacity, in: 0.1...1.0, step: 0.05)
                        .tint(DetailPalette.primary)
                        .onChange(of: watermarkOpacity) { _, _ in
                            isTextFieldFocused = false
                            updatePreview()
                        }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.15), radius: 16, y: -4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(DetailPalette.border, lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .onTapGesture {
            // 点击面板空白区域时收起键盘
            isTextFieldFocused = false
        }
    }
    
    private func updatePreview() {
        guard useWatermark, !watermarkText.isEmpty else {
            previewImage = nil
            return
        }
        
        let watermarkService = WatermarkServiceImpl()
        let style = WatermarkStyle.from(
            fontSize: watermarkFontSize,
            opacity: watermarkOpacity,
            spacing: watermarkSpacing
        )
        
        previewImage = watermarkService.applyWatermark(
            to: image,
            text: watermarkText,
            style: style
        )
    }
    
    private func shareImages() async {
        isSharing = true
        defer { isSharing = false }
        
        do {
            guard let images = item.images, !images.isEmpty else {
                print("❌ [FullImageView] No images to share")
                return
            }
            
            // 根据选择决定处理哪些图片
            let imagesToProcess: [UIImage]
            if shareAllImages {
                print("🔍 [FullImageView] Processing all \(images.count) images")
            } else {
                print("🔍 [FullImageView] Processing current image only")
            }
            
            var processedImages: [UIImage] = []
            let watermarkService = WatermarkServiceImpl()
            
            // 如果只分享当前图片，直接使用已加载的 image
            if !shareAllImages {
                var imageToShare = image
                
                if useWatermark, !watermarkText.isEmpty {
                    let style = WatermarkStyle.from(
                        fontSize: watermarkFontSize,
                        opacity: watermarkOpacity,
                        spacing: watermarkSpacing
                    )
                    if let watermarked = watermarkService.applyWatermark(
                        to: imageToShare,
                        text: watermarkText,
                        style: style
                    ) {
                        imageToShare = watermarked
                        print("✅ [FullImageView] Watermark applied to current image")
                    }
                }
                
                processedImages = [imageToShare]
            } else {
                // 处理全部图片
                for imageDTO in images {
                let imageData = try await itemService.getDecryptedImage(imageId: imageDTO.id)
                guard var uiImage = UIImage(data: imageData) else {
                    print("❌ [FullImageView] Failed to create UIImage")
                    continue
                }
                
                if useWatermark, !watermarkText.isEmpty {
                    let style = WatermarkStyle.from(
                        fontSize: watermarkFontSize,
                        opacity: watermarkOpacity,
                        spacing: watermarkSpacing
                    )
                    if let watermarkedImage = watermarkService.applyWatermark(
                        to: uiImage,
                        text: watermarkText,
                        style: style
                    ) {
                        uiImage = watermarkedImage
                        print("✅ [FullImageView] Watermark applied")
                    }
                }
                
                    processedImages.append(uiImage)
                }
            }
            
            print("✅ [FullImageView] Processed \(processedImages.count) images")
            await MainActor.run {
                showSystemShareSheet(items: processedImages)
            }
        } catch {
            print("❌ [FullImageView] Error: \(error)")
        }
    }
    
    private func showSystemShareSheet(items: [Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ [FullImageView] Cannot find root view controller")
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                       y: rootViewController.view.bounds.midY,
                                       width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        print("✅ [FullImageView] Presenting share sheet")
        topController.present(activityVC, animated: true)
    }
}

// MARK: - Watermark Config Sheet

struct WatermarkConfigSheet: View {
    let item: ItemDTO
    let itemService: ItemService
    
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var useWatermark = false
    @State private var watermarkText = ""
    @State private var watermarkFontSize: CGFloat = 30
    @State private var watermarkSpacing: WatermarkSpacing = .normal
    @State private var watermarkOpacity: CGFloat = 0.3
    @State private var isLoading = false
    @State private var previewImage: UIImage?
    @State private var originalImage: UIImage?
    @State private var isLoadingPreview = false
    
    var body: some View {
        NavigationStack {
            Form {
                // 预览区域
                if let preview = previewImage {
                    Section {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    } header: {
                        Text(localizationManager.localizedString("watermark.preview"))
                    }
                } else if isLoadingPreview {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .frame(height: 200)
                    } header: {
                        Text(localizationManager.localizedString("watermark.preview"))
                    }
                }
                
                Section {
                    Toggle(localizationManager.localizedString("watermark.add"), isOn: $useWatermark)
                        .onChange(of: useWatermark) { _, _ in
                            updatePreview()
                        }
                    
                    if useWatermark {
                        TextField(localizationManager.localizedString("watermark.text"), text: $watermarkText)
                            .textFieldStyle(.roundedBorder)
                            .placeholder(when: watermarkText.isEmpty) {
                                Text(localizationManager.localizedString("watermark.text.placeholder"))
                                    .foregroundColor(.secondary)
                            }
                            .onChange(of: watermarkText) { _, _ in
                                updatePreview()
                            }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(localizationManager.localizedString("watermark.fontsize"))
                                Spacer()
                                Text("\(Int(watermarkFontSize))")
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $watermarkFontSize, in: 20...80, step: 1)
                                .onChange(of: watermarkFontSize) { _, _ in
                                    updatePreview()
                                }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(localizationManager.localizedString("watermark.spacing"))
                                Spacer()
                            }
                            Picker(localizationManager.localizedString("watermark.spacing"), selection: $watermarkSpacing) {
                                ForEach(WatermarkSpacing.allCases) { spacing in
                                    Text(localizationManager.localizedString("watermark.spacing.\(spacing.localizedKey)")).tag(spacing)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: watermarkSpacing) { _, _ in
                                updatePreview()
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(localizationManager.localizedString("watermark.opacity"))
                                Spacer()
                                Text("\(Int(watermarkOpacity * 100))%")
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $watermarkOpacity, in: 0.1...1.0, step: 0.05)
                                .onChange(of: watermarkOpacity) { _, _ in
                                    updatePreview()
                                }
                        }
                    }
                } header: {
                    Text(localizationManager.localizedString("watermark.settings"))
                } footer: {
                    Text(localizationManager.localizedString("watermark.hint"))
                        .font(.caption)
                }
                .listRowSpacing(6)
            }
            .navigationTitle(localizationManager.localizedString("watermark.sheet.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localizationManager.localizedString("common.cancel")) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(localizationManager.localizedString("watermark.share")) {
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
                            Text(localizationManager.localizedString("watermark.preparing"))
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(.separator).opacity(0.8), lineWidth: 1.5)
                        )
                    }
                }
            }
            .task {
                await loadPreviewImage()
            }
        }
    }
    
    private func loadPreviewImage() async {
        isLoadingPreview = true
        defer { isLoadingPreview = false }
        
        guard let firstImage = item.images?.first else { return }
        
        do {
            let imageData = try await itemService.getDecryptedImage(imageId: firstImage.id)
            if let uiImage = UIImage(data: imageData) {
                originalImage = uiImage
                previewImage = uiImage
            }
        } catch {
            print("Error loading preview image: \(error)")
        }
    }
    
    private func updatePreview() {
        guard let original = originalImage else { return }
        
        if useWatermark && !watermarkText.isEmpty {
            let watermarkService = WatermarkServiceImpl()
            let style = WatermarkStyle.from(
                fontSize: watermarkFontSize,
                opacity: watermarkOpacity,
                spacing: watermarkSpacing
            )
            
            if let watermarked = watermarkService.applyWatermark(
                to: original,
                text: watermarkText,
                style: style
            ) {
                previewImage = watermarked
            }
        } else {
            previewImage = original
        }
    }
    
    private func showSystemShareSheet(items: [Any]) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ [WatermarkConfigSheet] Cannot find root view controller")
            return
        }
        
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // iPad 需要设置 popover
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX,
                                       y: rootViewController.view.bounds.midY,
                                       width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        // 找到最顶层的 presented view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        print("✅ [WatermarkConfigSheet] Presenting UIActivityViewController")
        topController.present(activityVC, animated: true)
    }
    
    private func shareImages() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // 获取所有图片
            guard let images = item.images, !images.isEmpty else {
                print("❌ [WatermarkConfigSheet] No images to share")
                return
            }
            
            print("🔍 [WatermarkConfigSheet] Processing \(images.count) images")
            var processedImages: [UIImage] = []
            let watermarkService = WatermarkServiceImpl()
            
            for imageDTO in images {
                // 获取解密后的图片数据
                let imageData = try await itemService.getDecryptedImage(imageId: imageDTO.id)
                guard var uiImage = UIImage(data: imageData) else {
                    print("❌ [WatermarkConfigSheet] Failed to create UIImage from data")
                    continue
                }
                
                print("✅ [WatermarkConfigSheet] Loaded image: \(uiImage.size)")
                
                // 如果需要添加水印
                if useWatermark, !watermarkText.isEmpty {
                    let style = WatermarkStyle.from(
                        fontSize: watermarkFontSize,
                        opacity: watermarkOpacity,
                        spacing: watermarkSpacing
                    )
                    print("🔍 [WatermarkConfigSheet] Applying watermark: '\(watermarkText)'")
                    if let watermarkedImage = watermarkService.applyWatermark(
                        to: uiImage,
                        text: watermarkText,
                        style: style
                    ) {
                        uiImage = watermarkedImage
                        print("✅ [WatermarkConfigSheet] Watermark applied")
                    } else {
                        print("❌ [WatermarkConfigSheet] Failed to apply watermark")
                    }
                }
                
                processedImages.append(uiImage)
            }
            
            print("✅ [WatermarkConfigSheet] Processed \(processedImages.count) images, showing share sheet")
            
            // 直接显示系统分享界面
            await MainActor.run {
                showSystemShareSheet(items: processedImages)
                // 延迟一点再dismiss，确保分享界面已显示
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            }
        } catch {
            print("❌ [WatermarkConfigSheet] Error processing images for sharing: \(error)")
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

fileprivate struct ZoomableScrollView<Content: View>: UIViewRepresentable {
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
