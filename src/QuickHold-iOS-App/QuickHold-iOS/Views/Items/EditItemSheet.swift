//
//  EditItemSheet.swift
//  QuickHold
//
//  编辑卡片界面
//

import SwiftUI
import PhotosUI
import AVFoundation
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
    @State private var isLoadingImages = false
    @State private var imagesToDelete: Set<UUID> = []
    @State private var imageToPreview: UIImage?
    @State private var showingCamera = false
    @State private var showingCameraUnavailableAlert = false
    @State private var imageToDeleteConfirm: UUID?  // 待确认删除的图片ID
    @State private var newImageIndexToDelete: Int?  // 待确认删除的新图片索引
    @State private var duplicateImageCount = 0  // 重复图片数量
    @State private var showingDuplicateAlert = false  // 显示重复提示
    @State private var duplicateFileCount = 0  // 重复文件数量
    @State private var showingDuplicateFileAlert = false  // 显示文件重复提示

    // 文件编辑相关 / File editing related
    @State private var newFileData: [FileData] = []
    @State private var filesToDelete: Set<UUID> = []
    @State private var showingDocumentPicker = false
   @State private var editedFileNames: [UUID: String] = [:]  // 跟踪修改的文件名
   @State private var editedNewFileNames: [Int: String] = [:]  // 跟踪新文件的修改
    @State private var fileToDeleteConfirm: UUID?  // 待确认删除的文件ID
    @State private var newFileIndexToDelete: Int?  // 待确认删除的新文件索引

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
                } else if item.type == .file {
                    fileContentSection
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
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray6))
                                    .foregroundStyle(.secondary)
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
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(localizationManager.localizedString(item.type.localizationKey))
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
        .fullScreenCover(isPresented: $showingCamera) {
            CameraPicker(isPresented: $showingCamera) { image in
                addCapturedImage(image)
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(item: $imageToPreview) { uiImage in
            SimpleImagePreview(image: uiImage)
        }
        .alert(localizationManager.localizedString("items.images.camera.unavailable"), isPresented: $showingCameraUnavailableAlert) {
            Button(localizationManager.localizedString("common.ok"), role: .cancel) {}
        } message: {
            Text(localizationManager.localizedString("items.images.camera.permission"))
        }
        .fileImporter(
            isPresented: $showingDocumentPicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: true
        ) { result in
            Task {
                await handleFileSelection(result)
            }
        }
        // 图片删除确认对话框
        .alert(localizationManager.localizedString("items.images.delete.confirm.title"), isPresented: .constant(imageToDeleteConfirm != nil)) {
            Button(localizationManager.localizedString("common.cancel"), role: .cancel) {
                imageToDeleteConfirm = nil
            }
            Button(localizationManager.localizedString("common.delete"), role: .destructive) {
                if let imageId = imageToDeleteConfirm {
                    imagesToDelete.insert(imageId)
                    imageToDeleteConfirm = nil
                }
            }
        } message: {
            Text(localizationManager.localizedString("items.images.delete.confirm.message"))
        }
        // 新图片删除确认对话框
        .alert(localizationManager.localizedString("items.images.delete.confirm.title"), isPresented: .constant(newImageIndexToDelete != nil)) {
            Button(localizationManager.localizedString("common.cancel"), role: .cancel) {
                newImageIndexToDelete = nil
            }
            Button(localizationManager.localizedString("common.delete"), role: .destructive) {
                if let index = newImageIndexToDelete {
                    newImageData.remove(at: index)
                    newImageIndexToDelete = nil
                }
            }
        } message: {
            Text(localizationManager.localizedString("items.images.delete.confirm.message"))
        }
        // 文件删除确认对话框
        .alert(localizationManager.localizedString("items.files.delete.confirm.title"), isPresented: .constant(fileToDeleteConfirm != nil)) {
            Button(localizationManager.localizedString("common.cancel"), role: .cancel) {
                fileToDeleteConfirm = nil
            }
            Button(localizationManager.localizedString("common.delete"), role: .destructive) {
                if let fileId = fileToDeleteConfirm {
                    filesToDelete.insert(fileId)
                    fileToDeleteConfirm = nil
                }
            }
        } message: {
            Text(localizationManager.localizedString("items.files.delete.confirm.message"))
        }
        // 新文件删除确认对话框
        .alert(localizationManager.localizedString("items.files.delete.confirm.title"), isPresented: .constant(newFileIndexToDelete != nil)) {
            Button(localizationManager.localizedString("common.cancel"), role: .cancel) {
                newFileIndexToDelete = nil
            }
            Button(localizationManager.localizedString("common.delete"), role: .destructive) {
                if let index = newFileIndexToDelete {
                    newFileData.remove(at: index)
                    newFileIndexToDelete = nil
                }
            }
        } message: {
            Text(localizationManager.localizedString("items.files.delete.confirm.message"))
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

            // 显示现有图片和新添加的图片
            if let existingImages = item.images, !existingImages.isEmpty || !newImageData.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // 现有图片
                        ForEach(existingImages.filter { !imagesToDelete.contains($0.id) }) { image in
                            if let thumbnailData = image.thumbnailData,
                               let uiImage = UIImage(data: thumbnailData) {
                                ZStack(alignment: .topTrailing) {
                                    Button {
                                        Task {
                                            do {
                                                let fullImageData = try await itemService.getDecryptedImage(imageId: image.id)
                                                if let fullImage = UIImage(data: fullImageData) {
                                                    await MainActor.run {
                                                        imageToPreview = fullImage
                                                    }
                                                }
                                            } catch {
                                                print("❌ [EditItemSheet] 加载原图失败: \(error)")
                                            }
                                        }
                                    } label: {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        imageToDeleteConfirm = image.id
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.white, .red)
                                            .frame(width: 44, height: 44)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .offset(x: 8, y: -8)
                                }
                            }
                        }

                        // 新添加的图片
                        ForEach(newImageData.indices, id: \.self) { index in
                            if let uiImage = UIImage(data: newImageData[index].data) {
                                ZStack(alignment: .topTrailing) {
                                    Button {
                                        imageToPreview = uiImage
                                    } label: {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 100, height: 100)
                                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                    .buttonStyle(.plain)

                                    Button {
                                        newImageIndexToDelete = index
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.white, .red)
                                            .frame(width: 44, height: 44)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
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
        print("📸 [EditItemSheet] loadImages: 开始加载 \(items.count) 个项目")
        
        var newImages: [ImageData] = []
        var duplicateCount = 0
        
        // 获取现有图片的哈希值
        var existingHashes = Set<String>()
        
        // 添加已经存在的图片哈希值
        if let existingImages = item.images {
            for image in existingImages {
                do {
                    let imageData = try await itemService.getDecryptedImage(imageId: image.id)
                    let hash = imageData.sha256Hash()
                    existingHashes.insert(hash)
                } catch {
                    print("⚠️ [EditItemSheet] loadImages: 无法加载现有图片 \(image.id): \(error)")
                }
            }
        }
        
        // 添加已经在 newImageData 中的图片哈希值
        for imageData in newImageData {
            let hash = imageData.data.sha256Hash()
            existingHashes.insert(hash)
        }
        
        print("🔑 [EditItemSheet] loadImages: 已有 \(existingHashes.count) 个图片哈希值")
        
        // 加载新选择的图片
        for (index, item) in items.enumerated() {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let hash = data.sha256Hash()
                
                // 检查是否重复
                if existingHashes.contains(hash) {
                    duplicateCount += 1
                    print("⚠️ [EditItemSheet] loadImages: 第 \(index + 1) 个图片重复，跳过")
                } else {
                    let fileName = "image_\(UUID().uuidString).jpg"
                    newImages.append(ImageData(data: data, fileName: fileName))
                    existingHashes.insert(hash)
                    print("📸 [EditItemSheet] loadImages: 成功加载第 \(index + 1) 个图片，大小: \(data.count) bytes，文件名: \(fileName)")
                }
            } else {
                print("❌ [EditItemSheet] loadImages: 加载第 \(index + 1) 个项目失败")
            }
        }
        
        // 添加到 newImageData
        await MainActor.run {
            newImageData.append(contentsOf: newImages)
            
            // 如果有重复图片，显示提示
            if duplicateCount > 0 {
                duplicateImageCount = duplicateCount
                showingDuplicateAlert = true
            }
        }
        
        print("📸 [EditItemSheet] loadImages: 完成，共加载 \(newImages.count) 个新图片，跳过 \(duplicateCount) 个重复图片")
    }

    private func loadImagesAsFiles(from items: [PhotosPickerItem]) async {
        print("📁 [EditItemSheet] loadImagesAsFiles: 开始加载 \(items.count) 个项目作为文件")

        var newFiles: [FileData] = []
        var duplicateCount = 0
        
        // 获取现有文件的哈希值
        var existingHashes = Set<String>()
        
        // 添加已经存在的文件哈希值
        if let existingFiles = item.files {
            for file in existingFiles where !filesToDelete.contains(file.id) {
                do {
                    let fileData = try await itemService.getDecryptedFile(fileId: file.id)
                    let hash = fileData.sha256Hash()
                    existingHashes.insert(hash)
                } catch {
                    print("⚠️ [EditItemSheet] loadImagesAsFiles: 无法加载现有文件 \(file.id): \(error)")
                }
            }
        }
        
        // 添加已经在 newFileData 中的文件哈希值
        for fileData in newFileData {
            let hash = fileData.data.sha256Hash()
            existingHashes.insert(hash)
        }

        for (index, item) in items.enumerated() {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let hash = data.sha256Hash()
                
                // 检查是否重复
                if existingHashes.contains(hash) {
                    duplicateCount += 1
                    print("⚠️ [EditItemSheet] loadImagesAsFiles: 第 \(index + 1) 个文件重复，跳过")
                } else {
                    // 尝试确定文件类型
                    let mimeType: String
                    let fileExtension: String

                    // 简单的 MIME 类型检测（基于数据头）
                    if data.count >= 2 {
                        let header = data.prefix(2)
                        if header[0] == 0xFF && header[1] == 0xD8 {
                            mimeType = "image/jpeg"
                            fileExtension = "jpg"
                        } else if data.count >= 4 && header[0] == 0x89 && header[1] == 0x50 {
                            mimeType = "image/png"
                            fileExtension = "png"
                        } else {
                            mimeType = "application/octet-stream"
                            fileExtension = "dat"
                        }
                    } else {
                        mimeType = "application/octet-stream"
                        fileExtension = "dat"
                    }

                    let fileName = "file_\(UUID().uuidString).\(fileExtension)"
                    newFiles.append(FileData(data: data, fileName: fileName, mimeType: mimeType))
                    existingHashes.insert(hash)
                    print("📁 [EditItemSheet] loadImagesAsFiles: 成功加载第 \(index + 1) 个文件，大小: \(data.count) bytes，文件名: \(fileName)，MIME: \(mimeType)")
                }
            } else {
                print("❌ [EditItemSheet] loadImagesAsFiles: 加载第 \(index + 1) 个项目失败")
            }
        }
        
        await MainActor.run {
            newFileData.append(contentsOf: newFiles)
            
            // 如果有重复文件，显示提示
            if duplicateCount > 0 {
                duplicateFileCount = duplicateCount
                showingDuplicateFileAlert = true
            }
        }
        
        print("📁 [EditItemSheet] loadImagesAsFiles: 完成，共加载 \(newFiles.count) 个新文件，跳过 \(duplicateCount) 个重复文件")
    }

    private func addCapturedImage(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return }
        let fileName = "camera_\(Date().timeIntervalSince1970).jpg"

        // 根据卡片类型决定添加到哪个数组
        if item.type == .file {
            // 文件卡片：作为普通文件添加
            newFileData.append(FileData(data: data, fileName: fileName, mimeType: "image/jpeg"))
            print("📸 [EditItemSheet] addCapturedImage: 添加拍摄照片到 newFileData，文件名: \(fileName)，大小: \(data.count) bytes")
        } else {
            // 图片卡片：作为图片添加
            newImageData.append(ImageData(data: data, fileName: fileName))
            print("📸 [EditItemSheet] addCapturedImage: 添加拍摄照片到 newImageData，文件名: \(fileName)，大小: \(data.count) bytes")
        }
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

    private func handleFileSelection(_ result: Result<[URL], Error>) async {
        do {
            let urls = try result.get()
            var newFiles: [FileData] = []
            var duplicateCount = 0
            
            // 获取现有文件的哈希值
            var existingHashes = Set<String>()
            
            // 添加已经存在的文件哈希值
            if let existingFiles = item.files {
                for file in existingFiles where !filesToDelete.contains(file.id) {
                    do {
                        let fileData = try await itemService.getDecryptedFile(fileId: file.id)
                        let hash = fileData.sha256Hash()
                        existingHashes.insert(hash)
                    } catch {
                        print("⚠️ [EditItemSheet] handleFileSelection: 无法加载现有文件 \(file.id): \(error)")
                    }
                }
            }
            
            // 添加已经在 newFileData 中的文件哈希值
            for fileData in newFileData {
                let hash = fileData.data.sha256Hash()
                existingHashes.insert(hash)
            }
            
            // 加载新选择的文件
            for url in urls {
                guard url.startAccessingSecurityScopedResource() else { continue }
                defer { url.stopAccessingSecurityScopedResource() }

                let data = try Data(contentsOf: url)
                let hash = data.sha256Hash()
                
                // 检查是否重复
                if existingHashes.contains(hash) {
                    duplicateCount += 1
                    print("⚠️ [EditItemSheet] handleFileSelection: 文件 \(url.lastPathComponent) 重复，跳过")
                } else {
                    let fileName = url.lastPathComponent
                    let mimeType = url.mimeType()
                    newFiles.append(FileData(data: data, fileName: fileName, mimeType: mimeType))
                    existingHashes.insert(hash)
                    print("📁 [EditItemSheet] handleFileSelection: 成功加载文件 \(fileName)")
                }
            }
            
            await MainActor.run {
                newFileData.append(contentsOf: newFiles)
                
                // 如果有重复文件，显示提示
                if duplicateCount > 0 {
                    duplicateFileCount = duplicateCount
                    showingDuplicateFileAlert = true
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
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
            } else if item.type == .image {
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
            } else if item.type == .file {
                print("💾 [EditItemSheet] saveChanges: 保存文件类型卡片")
                print("💾 [EditItemSheet] saveChanges: newFileData.count = \(newFileData.count)")
                print("💾 [EditItemSheet] saveChanges: newImageData.count = \(newImageData.count)")
                print("💾 [EditItemSheet] saveChanges: filesToDelete.count = \(filesToDelete.count)")
                print("💾 [EditItemSheet] saveChanges: imagesToDelete.count = \(imagesToDelete.count)")

                _ = try await itemService.updateFileItem(
                    id: item.id,
                    title: title,
                    tags: tags
                )

                // 删除标记的文件 / Delete marked files
                for fileId in filesToDelete {
                    print("🗑️ [EditItemSheet] saveChanges: 删除文件 \(fileId)")
                    try await itemService.removeFile(id: fileId)
                }

                // 更新现有文件名 / Update existing file names
                for (fileId, newName) in editedFileNames {
                    if !newName.isEmpty {
                        print("✏️ [EditItemSheet] saveChanges: 更新文件名 \(fileId) -> \(newName)")
                        try await itemService.updateFileName(id: fileId, newName: newName)
                    }
                }

                // 添加新文件（应用修改的文件名）/ Add new files with edited names
                if !newFileData.isEmpty {
                    print("📁 [EditItemSheet] saveChanges: 添加 \(newFileData.count) 个新文件")
                    var filesToAdd = newFileData
                    for (index, newName) in editedNewFileNames {
                        if index < filesToAdd.count && !newName.isEmpty {
                            filesToAdd[index] = FileData(
                                data: filesToAdd[index].data,
                                fileName: newName,
                                mimeType: filesToAdd[index].mimeType
                            )
                        }
                    }
                    try await itemService.addFiles(to: item.id, files: filesToAdd)
                    print("✅ [EditItemSheet] saveChanges: 成功添加 \(filesToAdd.count) 个文件")
                }

                // 删除标记的图片 / Delete marked images
                for imageId in imagesToDelete {
                    print("🗑️ [EditItemSheet] saveChanges: 删除图片 \(imageId)")
                    try await itemService.removeImage(id: imageId)
                }

                // 添加新图片 / Add new images
                if !newImageData.isEmpty {
                    print("🖼️ [EditItemSheet] saveChanges: 添加 \(newImageData.count) 个新图片")
                    try await itemService.addImages(to: item.id, images: newImageData)
                    print("✅ [EditItemSheet] saveChanges: 成功添加 \(newImageData.count) 个图片")
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

    // MARK: - File Content Section

    private var fileContentSection: some View {
        Section {
            // 选择文件按钮
            Button {
                showingDocumentPicker = true
            } label: {
                HStack {
                    Image(systemName: "doc.badge.plus")
                    Text(localizationManager.localizedString("items.files.select"))
                    Spacer()
                    if !newFileData.isEmpty {
                        Text("+\(newFileData.count)")
                            .foregroundStyle(.green)
                    }
                }
            }

            // 相机拍摄按钮
            Button {
                requestCameraAccessAndPresent()
            } label: {
                HStack {
                    Image(systemName: "camera")
                    Text(localizationManager.localizedString("items.files.camera"))
                    Spacer()
                }
            }
            .disabled(showingCamera || !UIImagePickerController.isSourceTypeAvailable(.camera))

            // 添加图片/视频按钮
            PhotosPicker(selection: $selectedImages, maxSelectionCount: 10, matching: .any(of: [.images, .videos])) {
                HStack {
                    Image(systemName: "photo.badge.plus")
                    Text(localizationManager.localizedString("items.files.select.media"))
                    Spacer()
                    if !newFileData.isEmpty {
                        Text("+\(newFileData.count)")
                            .foregroundStyle(.green)
                    }
                }
            }
            .onChange(of: selectedImages) { newItems in
                Task { await loadImagesAsFiles(from: newItems) }
            }

            // 显示现有文件和新添加的文件
            if let existingFiles = item.files, !existingFiles.isEmpty || !newFileData.isEmpty {
                // 现有文件
                ForEach(existingFiles.filter { !filesToDelete.contains($0.id) }) { file in
                    HStack {
                        Image(systemName: fileIcon(for: file.mimeType))
                            .font(.title2)
                            .foregroundStyle(.orange)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                TextField("", text: Binding(
                                    get: {
                                        let fileName = editedFileNames[file.id] ?? file.fileName
                                        return (fileName as NSString).deletingPathExtension
                                    },
                                    set: { newName in
                                        let ext = (file.fileName as NSString).pathExtension
                                        editedFileNames[file.id] = ext.isEmpty ? newName : "\(newName).\(ext)"
                                    }
                                ))
                                .font(.body)
                                .textFieldStyle(.plain)

                                if !(file.fileName as NSString).pathExtension.isEmpty {
                                    Text(".\((file.fileName as NSString).pathExtension)")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Text(formatFileSize(file.fileSize))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            fileToDeleteConfirm = file.id
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // 新添加的文件
                ForEach(newFileData.indices, id: \.self) { index in
                    HStack {
                        Image(systemName: fileIcon(for: newFileData[index].mimeType))
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 32)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                TextField("", text: Binding(
                                    get: {
                                        let fileName = editedNewFileNames[index] ?? newFileData[index].fileName
                                        return (fileName as NSString).deletingPathExtension
                                    },
                                    set: { newName in
                                        let ext = (newFileData[index].fileName as NSString).pathExtension
                                        editedNewFileNames[index] = ext.isEmpty ? newName : "\(newName).\(ext)"
                                    }
                                ))
                                .font(.body)
                                .textFieldStyle(.plain)

                                if !(newFileData[index].fileName as NSString).pathExtension.isEmpty {
                                    Text(".\((newFileData[index].fileName as NSString).pathExtension)")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Text(formatFileSize(Int64(newFileData[index].data.count)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Button {
                            newFileIndexToDelete = index
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // 显示图片和视频
            if (item.images?.isEmpty == false) || !newImageData.isEmpty {
                let existingImages = item.images ?? []
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
                                        imageToDeleteConfirm = image.id
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.white, .red)
                                            .frame(width: 44, height: 44)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
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
                                        newImageIndexToDelete = index
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(.white, .red)
                                            .frame(width: 44, height: 44)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .offset(x: 8, y: -8)
                                }
                            }
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
    }

    private func fileIcon(for mimeType: String) -> String {
        if mimeType.hasPrefix("image/") {
            return "photo"
        } else if mimeType.hasPrefix("video/") {
            return "video"
        } else if mimeType.hasPrefix("audio/") {
            return "music.note"
        } else if mimeType.contains("pdf") {
            return "doc.text"
        } else if mimeType.contains("zip") || mimeType.contains("archive") {
            return "archivebox"
        } else {
            return "doc"
        }
    }

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - URL Extension

extension URL {
    func mimeType() -> String {
        if let mimeType = UTType(filenameExtension: self.pathExtension)?.preferredMIMEType {
            return mimeType
        }
        return "application/octet-stream"
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

extension UIImage: Identifiable {
    public var id: String {
        UUID().uuidString
    }
}

//// MARK: - Simple Image Preview (for editing)
//
//struct SimpleImagePreview: View {
//    let image: UIImage
//    
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        ZStack {
//            Color.black
//                .ignoresSafeArea()
//            
//            // 可缩放的图片
//            ZoomableScrollView {
//                Image(uiImage: image)
//                    .resizable()
//                    .scaledToFit()
//            }
//            
//            // 顶部关闭按钮
//            VStack {
//                HStack {
//                    Spacer()
//                    
//                    Button {
//                        dismiss()
//                    } label: {
//                        Image(systemName: "xmark.circle.fill")
//                            .font(.title2)
//                            .foregroundStyle(.white, .black.opacity(0.5))
//                            .frame(width: 44, height: 44)
//                            .contentShape(Rectangle())
//                    }
//                    .buttonStyle(.plain)
//                    .padding()
//                }
//                
//                Spacer()
//            }
//        }
//    }
//}

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

// MARK: - Data Extension for SHA256 Hash

import CryptoKit

extension Data {
    func sha256Hash() -> String {
        let hash = SHA256.hash(data: self)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
