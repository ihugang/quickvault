//
//  CreateItemSheet.swift
//  QuickHold
//
//  优雅的创建卡片视图
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import AVFoundation
import QuickHoldCore

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
    @State private var isLoadingImages = false
    @State private var selectedFiles: [URL] = []
    @State private var fileData: [FileData] = []
    @State private var showingDocumentPicker = false
    @State private var showingCamera = false
    @State private var showingCameraUnavailableAlert = false
    @State private var isLoading = false
    @State private var availableTags: [String] = []
    @State private var duplicateImageCount = 0  // 重复图片数量
    @State private var showingDuplicateAlert = false  // 显示重复提示
    @State private var duplicateFileCount = 0  // 重复文件数量
    @State private var showingDuplicateFileAlert = false  // 显示文件重复提示

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
                        } else if selectedType == .image {
                            imageContentSection
                        } else if selectedType == .file {
                            fileContentSection
                        }
                        
                        // 标签
                        tagsSection
                    }
                }
                
                if isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle(selectedType == nil ? localizationManager.localizedString("items.create.selecttype") : String(format: localizationManager.localizedString("items.create.title"), localizationManager.localizedString(selectedType!.localizationKey)))
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
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker(isPresented: $showingCamera) { image in
                addCapturedImage(image)
            }
            .ignoresSafeArea()
        }
        .alert(localizationManager.localizedString("items.images.camera.unavailable"), isPresented: $showingCameraUnavailableAlert) {
            Button(localizationManager.localizedString("common.ok"), role: .cancel) {}
        } message: {
            Text(localizationManager.localizedString("items.images.camera.permission"))
        }
        // 重复图片提示对话框
        .alert(localizationManager.localizedString("items.images.duplicate.title"), isPresented: $showingDuplicateAlert) {
            Button(localizationManager.localizedString("common.ok"), role: .cancel) {
                duplicateImageCount = 0
            }
        } message: {
            Text(String(format: localizationManager.localizedString("items.images.duplicate.message"), duplicateImageCount))
        }
        // 重复文件提示对话框
        .alert(localizationManager.localizedString("items.files.duplicate.title"), isPresented: $showingDuplicateFileAlert) {
            Button(localizationManager.localizedString("common.ok"), role: .cancel) {
                duplicateFileCount = 0
            }
        } message: {
            Text(String(format: localizationManager.localizedString("items.files.duplicate.message"), duplicateFileCount))
        }
        .task {
            await loadAvailableTags()
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
            
            Button {
                withAnimation {
                    selectedType = .file
                }
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.orange.opacity(0.1))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "folder.fill")
                            .font(.title2)
                            .foregroundStyle(.orange)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localizationManager.localizedString("items.type.file"))
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(localizationManager.localizedString("items.type.file.desc"))
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
            // 相机拍摄按钮
            Button {
                requestCameraAccessAndPresent()
            } label: {
                HStack {
                    Image(systemName: "camera")
                    Text(localizationManager.localizedString("items.images.camera"))
                    Spacer()
                }
            }
            .disabled(showingCamera || !UIImagePickerController.isSourceTypeAvailable(.camera))

            // 相册选择按钮
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
            .onChange(of: selectedImages) { newItems in
                guard !newItems.isEmpty else { return }
                isLoadingImages = true
                Task {
                    await loadImages(from: newItems)
                    await MainActor.run {
                        isLoadingImages = false
                    }
                }
            }

            if isLoadingImages {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(localizationManager.localizedString("common.loading"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
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
    
    // MARK: - File Content
    
    private var fileContentSection: some View {
        Section {
            Button {
                showingDocumentPicker = true
            } label: {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text(localizationManager.localizedString("items.files.select"))
                    Spacer()
                    if !fileData.isEmpty {
                        Text(String(format: localizationManager.localizedString("items.files.count"), fileData.count))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .foregroundStyle(.primary)
            
            if !fileData.isEmpty {
                ForEach(fileData.indices, id: \.self) { index in
                    HStack {
                        Image(systemName: fileIcon(for: fileData[index].mimeType))
                            .font(.title2)
                            .foregroundStyle(.orange)
                            .frame(width: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(fileData[index].fileName)
                                .font(.body)
                                .lineLimit(1)
                            
                            Text(formatFileSize(fileData[index].data.count))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Button {
                            fileData.remove(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        } header: {
            Text(localizationManager.localizedString("items.files.section"))
        } footer: {
            Text(localizationManager.localizedString("items.files.limit"))
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.pdf, .text, .archive, .data],
            allowsMultipleSelection: true
        ) { result in
            Task { await loadFiles(from: result) }
        }
    }
    
    // MARK: - Tags

    private var tagsSection: some View {
        Section {
            // 输入框
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
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(.systemGray6))
                            )
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
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color(.systemGray6))
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
        } else if selectedType == .image {
            return !imageData.isEmpty
        } else if selectedType == .file {
            return !fileData.isEmpty
        }
        return false
    }
    
    private func addTag() {
        let trimmed = tagInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !tags.contains(trimmed) else { return }
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
    
    private func loadImages(from items: [PhotosPickerItem]) async {
        var newImages: [ImageData] = []
        var duplicateCount = 0
        
        // 获取已有图片的哈希值
        var existingHashes = Set<String>()
        for imageData in imageData {
            let hash = imageData.data.sha256Hash()
            existingHashes.insert(hash)
        }
        
        // 加载新选择的图片
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let hash = data.sha256Hash()
                
                // 检查是否重复
                if existingHashes.contains(hash) {
                    duplicateCount += 1
                } else {
                    let fileName = item.itemIdentifier ?? UUID().uuidString
                    newImages.append(ImageData(data: data, fileName: fileName + ".jpg"))
                    existingHashes.insert(hash)
                }
            }
        }
        
        // 添加到 imageData
        await MainActor.run {
            imageData.append(contentsOf: newImages)
            
            // 如果有重复图片，显示提示
            if duplicateCount > 0 {
                duplicateImageCount = duplicateCount
                showingDuplicateAlert = true
            }
        }
    }

    private func addCapturedImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        let fileName = "camera_\(Date().timeIntervalSince1970).jpg"
        imageData.append(ImageData(data: data, fileName: fileName))
    }

    private func requestCameraAccessAndPresent() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera),
              UIImagePickerController.isCameraDeviceAvailable(.rear) || UIImagePickerController.isCameraDeviceAvailable(.front) else {
            showingCameraUnavailableAlert = true
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showingCamera = true
                    } else {
                        showingCameraUnavailableAlert = true
                    }
                }
            }
        default:
            showingCameraUnavailableAlert = true
        }
    }

    private func loadFiles(from result: Result<[URL], Error>) async {
        do {
            let urls = try result.get()
            var newFiles: [FileData] = []
            var duplicateCount = 0
            
            // 获取已有文件的哈希值
            var existingHashes = Set<String>()
            for fileData in fileData {
                let hash = fileData.data.sha256Hash()
                existingHashes.insert(hash)
            }
            
            for url in urls {
                // 开始访问安全作用域资源
                guard url.startAccessingSecurityScopedResource() else {
                    print("Failed to access security-scoped resource: \(url)")
                    continue
                }
                
                defer {
                    // 确保在函数退出时停止访问
                    url.stopAccessingSecurityScopedResource()
                }
                
                // 读取文件数据
                let data = try Data(contentsOf: url)
                let hash = data.sha256Hash()
                
                // 检查是否重复
                if existingHashes.contains(hash) {
                    duplicateCount += 1
                    print("⚠️ [CreateItemSheet] loadFiles: 文件 \(url.lastPathComponent) 重复，跳过")
                } else {
                    let fileName = url.lastPathComponent
                    let mimeType = getMimeType(for: url)
                    newFiles.append(FileData(data: data, fileName: fileName, mimeType: mimeType))
                    existingHashes.insert(hash)
                    print("📁 [CreateItemSheet] loadFiles: 成功加载文件 \(fileName)")
                }
            }
            
            await MainActor.run {
                fileData.append(contentsOf: newFiles)
                
                // 如果有重复文件，显示提示
                if duplicateCount > 0 {
                    duplicateFileCount = duplicateCount
                    showingDuplicateFileAlert = true
                }
            }
        } catch {
            print("Error loading files: \(error)")
        }
    }
    
    private func getMimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension.lowercased()
        switch pathExtension {
        case "pdf":
            return "application/pdf"
        case "txt":
            return "text/plain"
        case "doc":
            return "application/msword"
        case "docx":
            return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        case "xls":
            return "application/vnd.ms-excel"
        case "xlsx":
            return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        case "zip":
            return "application/zip"
        case "rar":
            return "application/vnd.rar"
        default:
            return "application/octet-stream"
        }
    }
    
    private func fileIcon(for mimeType: String) -> String {
        if mimeType.hasPrefix("application/pdf") {
            return "doc.fill"
        } else if mimeType.hasPrefix("text/") {
            return "doc.text.fill"
        } else if mimeType.hasPrefix("application/zip") || mimeType.hasPrefix("application/vnd.rar") {
            return "doc.zipper"
        } else if mimeType.contains("word") {
            return "doc.richtext.fill"
        } else if mimeType.contains("excel") || mimeType.contains("spreadsheet") {
            return "tablecells.fill"
        } else {
            return "doc.fill"
        }
    }
    
    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
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
            } else if selectedType == .image {
                _ = try await itemService.createImageItem(
                    title: title,
                    images: imageData,
                    tags: tags
                )
            } else if selectedType == .file {
                _ = try await itemService.createFileItem(
                    title: title,
                    files: fileData,
                    tags: tags
                )
            }

            // 立即触发 iCloud 同步 / Trigger iCloud sync immediately
            CloudSyncMonitor.shared.manualSync()

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

// MARK: - Camera Picker

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onImageCaptured: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        if UIImagePickerController.isCameraDeviceAvailable(.rear) {
            picker.cameraDevice = .rear
        } else if UIImagePickerController.isCameraDeviceAvailable(.front) {
            picker.cameraDevice = .front
        }
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}
