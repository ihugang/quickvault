import PhotosUI
import QuickVaultCore
import SwiftUI

/// Attachment list view / 附件列表视图
struct AttachmentListView: View {
    let cardId: UUID
    @StateObject private var viewModel: AttachmentListViewModel
    @State private var showImagePicker = false
    @State private var selectedAttachment: AttachmentDTO?
    @State private var showWatermarkSheet = false
    @State private var showExportSheet = false
    @State private var attachmentToExport: AttachmentDTO?
    
    init(cardId: UUID) {
        self.cardId = cardId
        _viewModel = StateObject(wrappedValue: AttachmentListViewModel(cardId: cardId))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if !viewModel.attachments.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("附件 / Attachments")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Button {
                            showImagePicker = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                    }
                    
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                        ForEach(viewModel.attachments) { attachment in
                            AttachmentThumbnailView(attachment: attachment)
                                .onTapGesture {
                                    print("🔍 [AttachmentListView] Tapped on attachment: \(attachment.fileName)")
                                    print("🔍 [AttachmentListView] Attachment ID: \(attachment.id)")
                                    selectedAttachment = attachment
                                    print("🔍 [AttachmentListView] selectedAttachment set to: \(selectedAttachment?.fileName ?? "nil")")
                                }
                                .contextMenu {
                                    Button {
                                        selectedAttachment = attachment
                                        showWatermarkSheet = true
                                    } label: {
                                        Label("水印 / Watermark", systemImage: "textformat")
                                    }
                                    
                                    Button {
                                        attachmentToExport = attachment
                                        showExportSheet = true
                                    } label: {
                                        Label("导出 / Export", systemImage: "square.and.arrow.up")
                                    }
                                    
                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteAttachment(attachment.id)
                                        }
                                    } label: {
                                        Label("删除 / Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(cardId: cardId, viewModel: viewModel)
        }
        .sheet(item: $selectedAttachment) { attachment in
            AttachmentDetailSheet(attachment: attachment, viewModel: viewModel)
                .onAppear {
                    print("🔍 [AttachmentListView] Sheet appeared for: \(attachment.fileName)")
                }
        }
        .sheet(isPresented: $showWatermarkSheet) {
            if let attachment = selectedAttachment {
                WatermarkSheet(attachment: attachment, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showExportSheet) {
            if let attachment = attachmentToExport {
                ExportWatermarkSheet(attachment: attachment, viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadAttachments()
        }
        .overlay {
            if let toast = viewModel.toastMessage {
                ToastView(message: toast)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            viewModel.clearToast()
                        }
                    }
            }
        }
    }
}

/// Attachment thumbnail view / 附件缩略图视图
struct AttachmentThumbnailView: View {
    let attachment: AttachmentDTO
    
    var body: some View {
        ZStack {
            if let thumbnail = attachment.thumbnailImage {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // PDF or no thumbnail
                Image(systemName: attachment.mimeType.contains("pdf") ? "doc.fill" : "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
            
            // Watermark indicator
            if attachment.hasWatermark {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: "drop.fill")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(4)
            }
        }
        .frame(width: 100, height: 100)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Attachment detail sheet / 附件详情表单
struct AttachmentDetailSheet: View {
    let attachment: AttachmentDTO
    @ObservedObject var viewModel: AttachmentListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var imageData: Data?
    @State private var isLoading = true
    @State private var loadError: String?
    
    init(attachment: AttachmentDTO, viewModel: AttachmentListViewModel) {
        self.attachment = attachment
        self.viewModel = viewModel
        print("🔍 [AttachmentDetailSheet] Initialized for: \(attachment.fileName)")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isLoading {
                    VStack {
                        ProgressView()
                        Text("加载中... / Loading...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                } else if let data = imageData, let image = UIImage(data: data) {
                    ZoomableScrollView {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                    .onAppear {
                        print("📸 [AttachmentView] Image displayed successfully, size: \(image.size)")
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text("无法加载附件 / Unable to load attachment")
                            .foregroundStyle(.secondary)
                        if let error = loadError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding()
                        }
                        Text("数据大小: \(imageData?.count ?? 0) bytes")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
            }
            .navigationTitle(attachment.fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭 / Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        Task {
                            await viewModel.shareAttachment(attachment)
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .task {
                print("🔍 [AttachmentView] Starting to load attachment: \(attachment.id)")
                print("🔍 [AttachmentView] Attachment fileName: \(attachment.fileName)")
                print("🔍 [AttachmentView] Attachment mimeType: \(attachment.mimeType)")
                
                do {
                    imageData = try await viewModel.getAttachmentData(attachment.id)
                    print("✅ [AttachmentView] Data loaded successfully, size: \(imageData?.count ?? 0) bytes")
                    
                    if let data = imageData {
                        if let image = UIImage(data: data) {
                            print("✅ [AttachmentView] UIImage created successfully, size: \(image.size)")
                        } else {
                            print("❌ [AttachmentView] Failed to create UIImage from data")
                        }
                    } else {
                        print("❌ [AttachmentView] imageData is nil after loading")
                    }
                } catch {
                    loadError = error.localizedDescription
                    print("❌ [AttachmentView] Failed to load attachment: \(error)")
                    print("❌ [AttachmentView] Error details: \(error.localizedDescription)")
                }
                isLoading = false
                print("🔍 [AttachmentView] Loading finished, isLoading: \(isLoading)")
            }
        }
    }
}

/// Watermark sheet / 水印表单
struct WatermarkSheet: View {
    let attachment: AttachmentDTO
    @ObservedObject var viewModel: AttachmentListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var watermarkText: String
    
    init(attachment: AttachmentDTO, viewModel: AttachmentListViewModel) {
        self.attachment = attachment
        self.viewModel = viewModel
        _watermarkText = State(initialValue: attachment.watermarkText ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("水印文字 / Watermark Text", text: $watermarkText)
                } header: {
                    Text("水印设置 / Watermark Settings")
                } footer: {
                    Text("水印将以半透明对角线方式覆盖在图片上\nWatermark will be overlaid diagonally on the image")
                }
                
                if attachment.hasWatermark {
                    Section {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.updateWatermark(attachment.id, text: nil)
                                dismiss()
                            }
                        } label: {
                            Text("移除水印 / Remove Watermark")
                        }
                    }
                }
            }
            .navigationTitle("水印 / Watermark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消 / Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("应用 / Apply") {
                        Task {
                            await viewModel.updateWatermark(attachment.id, text: watermarkText.isEmpty ? nil : watermarkText)
                            dismiss()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

/// Export watermark sheet / 导出水印输入界面
struct ExportWatermarkSheet: View {
    let attachment: AttachmentDTO
    @ObservedObject var viewModel: AttachmentListViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var watermarkText: String = ""
    @State private var addWatermark: Bool = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("export.add.watermark".localized, isOn: $addWatermark)
                    
                    if addWatermark {
                        TextField("export.watermark.placeholder".localized, text: $watermarkText)
                            .textFieldStyle(.roundedBorder)
                    }
                } header: {
                    Text("export.watermark.title".localized)
                } footer: {
                    Text("export.watermark.hint".localized)
                        .font(.caption)
                }
                
                Section {
                    Button {
                        Task {
                            let watermark = addWatermark && !watermarkText.isEmpty ? watermarkText : nil
                            await viewModel.shareAttachment(attachment, watermarkText: watermark)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("export.action".localized)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("export.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Image picker / 图片选择器
struct ImagePicker: UIViewControllerRepresentable {
    let cardId: UUID
    @ObservedObject var viewModel: AttachmentListViewModel
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 5
        config.filter = .any(of: [.images])
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            for result in results {
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                        guard let self = self, let image = image as? UIImage else { return }
                        
                        Task { @MainActor in
                            if let data = image.jpegData(compressionQuality: 0.9) {
                                let fileName = "IMG_\(Date().timeIntervalSince1970).jpg"
                                await self.parent.viewModel.addAttachment(data: data, fileName: fileName, mimeType: "image/jpeg")
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Attachment list view model / 附件列表视图模型
@MainActor
class AttachmentListViewModel: ObservableObject {
    @Published var attachments: [AttachmentDTO] = []
    @Published var isLoading = false
    @Published var toastMessage: String?
    @Published var shareURL: URL?
    
    private let cardId: UUID
    private let attachmentService: AttachmentService
    
    init(cardId: UUID) {
        self.cardId = cardId
        
        let persistenceController = PersistenceController.shared
        let watermarkService = WatermarkServiceImpl()
        
        self.attachmentService = AttachmentServiceImpl(
            persistenceController: persistenceController,
            cryptoService: CryptoServiceImpl.shared,
            watermarkService: watermarkService
        )
    }
    
    func loadAttachments() async {
        isLoading = true
        do {
            attachments = try await attachmentService.fetchAttachments(for: cardId)
        } catch {
            toastMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func addAttachment(data: Data, fileName: String, mimeType: String, watermarkText: String? = nil) async {
        isLoading = true
        do {
            let attachment = try await attachmentService.addAttachment(
                to: cardId,
                fileData: data,
                fileName: fileName,
                mimeType: mimeType,
                watermarkText: watermarkText
            )
            attachments.insert(attachment, at: 0)
            toastMessage = "已添加附件 / Attachment added"
        } catch {
            toastMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func deleteAttachment(_ id: UUID) async {
        do {
            try await attachmentService.deleteAttachment(id: id)
            attachments.removeAll { $0.id == id }
            toastMessage = "已删除附件 / Attachment deleted"
        } catch {
            toastMessage = error.localizedDescription
        }
    }
    
    func getAttachmentData(_ id: UUID) async throws -> Data {
        try await attachmentService.getAttachmentData(id: id)
    }
    
    func updateWatermark(_ id: UUID, text: String?) async {
        isLoading = true
        do {
            let updated = try await attachmentService.updateWatermark(id: id, text: text)
            if let index = attachments.firstIndex(where: { $0.id == id }) {
                attachments[index] = updated
            }
            toastMessage = text != nil ? "已应用水印 / Watermark applied" : "已移除水印 / Watermark removed"
        } catch {
            toastMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func shareAttachment(_ attachment: AttachmentDTO, watermarkText: String? = nil) async {
        do {
            let url = try await attachmentService.shareAttachment(id: attachment.id, watermarkText: watermarkText)
            shareURL = url
            
            // Present share sheet
            await MainActor.run {
                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    rootVC.present(activityVC, animated: true)
                }
            }
        } catch {
            toastMessage = error.localizedDescription
        }
    }
    
    func clearToast() {
        toastMessage = nil
    }
}

// MARK: - ZoomableScrollView for Attachments

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
        scrollView.showsVerticalScrollIndicator = true
        scrollView.showsHorizontalScrollIndicator = true
        scrollView.backgroundColor = .systemBackground
        
        let hostedView = context.coordinator.hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(hostedView)
        
        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostedView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            hostedView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
        
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

#Preview {
    AttachmentListView(cardId: UUID())
}
