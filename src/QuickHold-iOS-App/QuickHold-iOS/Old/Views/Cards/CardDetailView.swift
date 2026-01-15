import SwiftUI
import QuickHoldCore

/// Card detail view / 卡片详情视图
struct CardDetailView: View {
    let cardId: UUID
    @StateObject private var viewModel: CardDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
    
    init(cardId: UUID) {
        self.cardId = cardId
        let persistenceController = PersistenceController.shared
        let cryptoService = CryptoServiceImpl.shared
        let cardService = CardServiceImpl(persistenceController: persistenceController, cryptoService: cryptoService)
        _viewModel = StateObject(wrappedValue: CardDetailViewModel(cardService: cardService, cryptoService: cryptoService))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.card == nil {
                ProgressView()
            } else if let card = viewModel.card {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Card Header
                        CardHeaderView(card: card)
                        
                        // Document Photos (for ID cards, passports, etc.)
                        if isDocumentType(card.type) {
                            DocumentPhotosSection(cardId: card.id, cardType: card.type)
                        } else {
                            // Generic attachments for other card types
                            AttachmentListView(cardId: card.id)
                        }
                        
                        // Fields
                        FieldsSection(
                            fields: card.fields,
                            onCopy: { field in
                                viewModel.copyField(field)
                            }
                        )
                        
                        // Tags
                        if !card.tags.isEmpty {
                            TagsSection(tags: card.tags)
                        }
                        
                        // Timestamps
                        TimestampsSection(card: card)

                        // Export text button / 导出文本按钮
                        ExportButtonsSection(
                            onExportText: {
                                viewModel.exportAsText()
                            }
                        )
                    }
                    .padding()
                }
            } else {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: "error.generic".localized,
                    message: viewModel.errorMessage ?? "error.generic".localized
                )
            }
        }
        .navigationTitle(viewModel.card?.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        viewModel.copyCard()
                    } label: {
                        Label("common.copy".localized, systemImage: "doc.on.doc")
                    }

                    Button {
                        viewModel.exportAsText()
                    } label: {
                        Label("导出文本 / Export Text", systemImage: "doc.text")
                    }

                    Button {
                        showEditSheet = true
                    } label: {
                        Label("common.edit".localized, systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("common.delete".localized, systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("cards.delete.confirm".localized, isPresented: $showDeleteConfirmation) {
            Button("common.cancel".localized, role: .cancel) {}
            Button("common.delete".localized, role: .destructive) {
                Task {
                    if await viewModel.deleteCard() {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("cards.delete.confirm".localized)
        }
        .sheet(isPresented: $showEditSheet) {
            if let card = viewModel.card {
                CardEditorSheet(editingCard: card) {
                    Task {
                        await viewModel.loadCard(id: cardId)
                    }
                }
            }
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
        .task {
            await viewModel.loadCard(id: cardId)
        }
    }
}

/// Card header view / 卡片头部视图
struct CardHeaderView: View {
    let card: CardDTO
    
    var body: some View {
        HStack(spacing: 16) {
            cardTypeIcon
                .font(.title)
                .foregroundStyle(.white)
                .frame(width: 60, height: 60)
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(card.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if card.isPinned {
                        Image(systemName: "pin.fill")
                            .foregroundStyle(.orange)
                    }
                }
                
                Text(groupDisplayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
    
    private var cardTypeIcon: Image {
        switch card.type {
        case "Address":
            return Image(systemName: "mappin.circle.fill")
        case "Invoice":
            return Image(systemName: "doc.text.fill")
        default:
            return Image(systemName: "text.alignleft")
        }
    }
    
    private var groupDisplayName: String {
        switch card.group {
        case "Personal": return "cards.group.personal".localized
        case "Company": return "cards.group.company".localized
        default: return card.group
        }
    }
}

/// Fields section / 字段区域
struct FieldsSection: View {
    let fields: [CardFieldDTO]
    let onCopy: (CardFieldDTO) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("cards.field.label".localized)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            VStack(spacing: 0) {
                ForEach(fields.sorted(by: { $0.order < $1.order }), id: \.id) { field in
                    FieldRow(field: field, onCopy: { onCopy(field) })
                    
                    if field.id != fields.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        }
    }
}

/// Field row / 字段行
struct FieldRow: View {
    let field: CardFieldDTO
    let onCopy: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(field.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(field.value.isEmpty ? "-" : field.value)
                    .font(.body)
            }
            
            Spacer()
            
            if field.isCopyable && !field.value.isEmpty {
                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
    }
}

/// Tags section / 标签区域
struct TagsSection: View {
    let tags: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("cards.tags".localized)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
            }
        }
    }
}

/// Timestamps section / 时间戳区域
struct TimestampsSection: View {
    let card: CardDTO
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("cards.created".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(card.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text("cards.updated".localized)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(card.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

/// Flow layout for tags / 标签流式布局
fileprivate struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Helper Functions

private func isDocumentType(_ type: String) -> Bool {
    ["idCard", "passport", "businessLicense"].contains(type)
}

// MARK: - Document Photos Section

struct DocumentPhotosSection: View {
    let cardId: UUID
    let cardType: String
    @StateObject private var viewModel: AttachmentListViewModel
    @State private var selectedAttachment: AttachmentDTO?
    @State private var showExportAllSheet = false

    init(cardId: UUID, cardType: String) {
        self.cardId = cardId
        self.cardType = cardType
        _viewModel = StateObject(wrappedValue: AttachmentListViewModel(cardId: cardId))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("attachment.document.photos".localized)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                // Export all button (only show if there are attachments)
                if hasAttachments {
                    Button {
                        showExportAllSheet = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption)
                            Text("export.images.all".localized)
                                .font(.caption)
                        }
                        .foregroundStyle(.blue)
                    }
                }
            }

            let normalizedType = cardType.lowercased()

            if normalizedType == "idcard" {
                // 身份证：固定正反面
                HStack(spacing: 12) {
                    DocumentPhotoCard(
                        title: "ocr.idcard.front".localized,
                        attachment: findAttachment(fileName: "idcard_front.jpg"),
                        onTap: { attachment in
                            selectedAttachment = attachment
                        }
                    )

                    DocumentPhotoCard(
                        title: "ocr.idcard.back".localized,
                        attachment: findAttachment(fileName: "idcard_back.jpg"),
                        onTap: { attachment in
                            selectedAttachment = attachment
                        }
                    )
                }
            } else if normalizedType == "passport" {
                // 护照：信息页
                DocumentPhotoCard(
                    title: "ocr.passport.datapage".localized,
                    attachment: findAttachment(fileName: "passport_datapage.jpg"),
                    onTap: { attachment in
                        selectedAttachment = attachment
                    }
                )
            } else if normalizedType == "businesslicense" {
                // 营业执照
                DocumentPhotoCard(
                    title: "ocr.license.photo".localized,
                    attachment: findAttachment(fileName: "business_license.jpg"),
                    onTap: { attachment in
                        selectedAttachment = attachment
                    }
                )
            }
        }
        .sheet(item: $selectedAttachment) { attachment in
            AttachmentPreviewView(attachment: attachment)
        }
        .sheet(isPresented: $showExportAllSheet) {
            ExportAllImagesSheet(cardId: cardId)
        }
        .task {
            await viewModel.loadAttachments()
        }
    }

    private var hasAttachments: Bool {
        !viewModel.attachments.isEmpty
    }

    private func findAttachment(fileName: String) -> AttachmentDTO? {
        viewModel.attachments.first { $0.fileName == fileName }
    }
}

// MARK: - Document Photo Card

struct DocumentPhotoCard: View {
    let title: String
    let attachment: AttachmentDTO?
    let onTap: (AttachmentDTO) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let attachment = attachment, let thumbnail = attachment.thumbnailImage {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        onTap(attachment)
                    }
            } else {
                // 占位符
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray5))
                    .frame(height: 120)
                    .overlay {
                        VStack(spacing: 4) {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            Text("attachment.no.photo".localized)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Attachment Preview View

struct AttachmentPreviewView: View {
    let attachment: AttachmentDTO
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: AttachmentPreviewViewModel

    init(attachment: AttachmentDTO) {
        self.attachment = attachment
        _viewModel = StateObject(wrappedValue: AttachmentPreviewViewModel(attachmentId: attachment.id))
    }

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var showExportSheet = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let image = viewModel.image {
                    GeometryReader { geometry in
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .scaleEffect(scale)
                            .offset(offset)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = lastScale * value
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                        if scale < 1.0 {
                                            withAnimation {
                                                scale = 1.0
                                                lastScale = 1.0
                                                offset = .zero
                                                lastOffset = .zero
                                            }
                                        }
                                    }
                            )
                            .simultaneousGesture(
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1.0 {
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                            .onTapGesture(count: 2) {
                                withAnimation {
                                    if scale > 1.0 {
                                        scale = 1.0
                                        lastScale = 1.0
                                        offset = .zero
                                        lastOffset = .zero
                                    } else {
                                        scale = 2.5
                                        lastScale = 2.5
                                    }
                                }
                            }
                    }
                } else {
                    Text("attachment.load.failed".localized)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(attachment.fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close".localized) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showExportSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showExportSheet) {
                ExportSingleImageSheet(
                    attachmentId: attachment.id,
                    fileName: attachment.fileName
                )
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
}

// MARK: - Attachment Preview ViewModel

@MainActor
class AttachmentPreviewViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = true
    @Published var toastMessage: String?

    private let attachmentService = AttachmentServiceImpl.shared
    private let attachmentId: UUID

    init(attachmentId: UUID) {
        self.attachmentId = attachmentId
        Task {
            await loadImage()
        }
    }

    func loadImage() async {
        isLoading = true
        do {
            let data = try await attachmentService.getAttachmentData(id: attachmentId)
            image = UIImage(data: data)
        } catch {
            print("Failed to load attachment: \(error)")
        }
        isLoading = false
    }

    func clearToast() {
        toastMessage = nil
    }
}

// MARK: - Export Buttons Section

struct ExportButtonsSection: View {
    let onExportText: () -> Void

    var body: some View {
        // Text export button
        Button {
            onExportText()
        } label: {
            HStack {
                Image(systemName: "doc.text")
                Text("导出文本 / Export Text")
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

// MARK: - Export All Images Sheet

struct ExportAllImagesSheet: View {
    let cardId: UUID
    @Environment(\.dismiss) private var dismiss
    @State private var watermarkText: String = ""
    @State private var addWatermark: Bool = true
    @State private var watermarkFontSize: Double = 30  // 字号范围 20-80
    @State private var watermarkSpacing: WatermarkSpacing = .normal  // 行间距
    @State private var watermarkOpacity: Double = 0.3
    @State private var enableAdvancedOptions: Bool = false
    @State private var maxWidth: String = ""
    @State private var maxHeight: String = ""
    @State private var maxFileSize: String = ""
    @State private var isExporting = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var previewImages: [UIImage] = []
    @State private var isLoadingPreview = false
    @State private var selectedPreviewIndex = 0

    var body: some View {
        NavigationStack {
            Form {
                // Preview Section at top
                if !previewImages.isEmpty {
                    Section {
                        TabView(selection: $selectedPreviewIndex) {
                            ForEach(previewImages.indices, id: \.self) { index in
                                Image(uiImage: previewImages[index])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .tag(index)
                            }
                        }
                        .tabViewStyle(.page(indexDisplayMode: .always))
                        .frame(height: 300)

                        Text("\(selectedPreviewIndex + 1) / \(previewImages.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    } header: {
                        Text("export.preview".localized)
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
                        Text("export.preview".localized)
                    }
                }

                Section {
                    Toggle("export.add.watermark".localized, isOn: $addWatermark)

                    if addWatermark {
                        TextField("export.watermark.placeholder".localized, text: $watermarkText)
                            .textFieldStyle(.roundedBorder)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("export.watermark.fontsize".localized)
                                Spacer()
                                Text("\(Int(watermarkFontSize))")
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $watermarkFontSize, in: 20...80, step: 1)
                        }

                        Picker("export.watermark.spacing".localized, selection: $watermarkSpacing) {
                            ForEach(WatermarkSpacing.allCases) { spacing in
                                Text(spacing.displayName).tag(spacing)
                            }
                        }
                        .pickerStyle(.segmented)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("export.watermark.opacity".localized)
                                Spacer()
                                Text("\(Int(watermarkOpacity * 100))%")
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $watermarkOpacity, in: 0.1...1.0, step: 0.05)
                        }
                    }
                } header: {
                    Text("export.watermark.title".localized)
                } footer: {
                    Text("export.watermark.hint".localized)
                        .font(.caption)
                }
                .listRowSpacing(6)

                Section {
                    Toggle("export.advanced.options".localized, isOn: $enableAdvancedOptions)

                    if enableAdvancedOptions {
                        HStack {
                            Text("export.max.width".localized)
                            Spacer()
                            TextField("export.pixel".localized, text: $maxWidth)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }

                        HStack {
                            Text("export.max.height".localized)
                            Spacer()
                            TextField("export.pixel".localized, text: $maxHeight)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }

                        HStack {
                            Text("export.max.filesize".localized)
                            Spacer()
                            TextField("KB", text: $maxFileSize)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                    }
                } header: {
                    Text("export.size.compression".localized)
                } footer: {
                    if enableAdvancedOptions {
                        Text("export.hint.limits".localized)
                            .font(.caption)
                    }
                }
                .listRowSpacing(6)

                Section {
                    Button {
                        Task {
                            await exportAllImages()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("export.images.all".localized)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(isExporting)
                }
                .listRowSpacing(6)
            }
            .navigationTitle("export.images.all".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .task {
            await generatePreview()
        }
        .onChange(of: addWatermark) { _, _ in
            Task { await generatePreview() }
        }
        .onChange(of: watermarkText) { _, _ in
            Task { await generatePreview() }
        }
        .onChange(of: watermarkFontSize) { _, _ in
            Task { await generatePreview() }
        }
        .onChange(of: watermarkSpacing) { _, _ in
            Task { await generatePreview() }
        }
        .onChange(of: watermarkOpacity) { _, _ in
            Task { await generatePreview() }
        }
        .overlay {
            if showToast {
                ToastView(message: toastMessage)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showToast = false
                        }
                    }
            }
        }
    }

    private func exportAllImages() async {
        isExporting = true

        do {
            let attachmentService = AttachmentServiceImpl.shared
            let attachments = try await attachmentService.fetchAttachments(for: cardId)

            // Filter only image attachments
            let imageAttachments = attachments.filter { $0.mimeType.contains("image") }

            guard !imageAttachments.isEmpty else {
                toastMessage = "attachments.empty".localized
                showToast = true
                isExporting = false
                return
            }

            // Build export options
            let exportOptions = ImageExportOptions(
                maxWidth: maxWidth.isEmpty ? nil : CGFloat(Int(maxWidth) ?? 0),
                maxHeight: maxHeight.isEmpty ? nil : CGFloat(Int(maxHeight) ?? 0),
                maxFileSizeKB: maxFileSize.isEmpty ? nil : Int(maxFileSize),
                jpegQuality: 0.9
            )

            // Collect all processed image URLs
            var imageURLs: [URL] = []
            let watermark = addWatermark && !watermarkText.isEmpty ? watermarkText : nil

            for attachment in imageAttachments {
                let url = try await attachmentService.shareAttachment(
                    id: attachment.id,
                    watermarkText: watermark,
                    watermarkFontSize: watermarkFontSize,
                    watermarkSpacing: watermarkSpacing,
                    watermarkOpacity: watermarkOpacity,
                    exportOptions: exportOptions
                )
                imageURLs.append(url)
            }

            // Present share sheet with all images
            await MainActor.run {
                let activityVC = UIActivityViewController(activityItems: imageURLs, applicationActivities: nil)

                activityVC.completionWithItemsHandler = { [self] activityType, completed, returnedItems, error in
                    Task { @MainActor in
                        if let error = error {
                            toastMessage = "export.failed".localized + ": \(error.localizedDescription)"
                            showToast = true
                        } else if completed {
                            toastMessage = String(format: "export.images.count".localized, imageURLs.count)
                            showToast = true
                            // Close the sheet after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                dismiss()
                            }
                        }
                    }
                }

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    var presentingVC = rootVC
                    while let presented = presentingVC.presentedViewController {
                        presentingVC = presented
                    }
                    presentingVC.present(activityVC, animated: true)
                }
            }
        } catch {
            toastMessage = "export.failed".localized + ": \(error.localizedDescription)"
            showToast = true
        }

        isExporting = false
    }

    private func generatePreview() async {
        await MainActor.run {
            isLoadingPreview = true
        }

        do {
            let attachmentService = AttachmentServiceImpl.shared
            let attachments = try await attachmentService.fetchAttachments(for: cardId)

            // Filter only image attachments
            let imageAttachments = attachments.filter { $0.mimeType.contains("image") }

            guard !imageAttachments.isEmpty else {
                await MainActor.run {
                    isLoadingPreview = false
                }
                return
            }

            var processedImages: [UIImage] = []

            for attachment in imageAttachments {
                let data = try await attachmentService.getAttachmentData(id: attachment.id)
                guard let image = UIImage(data: data) else { continue }

                // Apply watermark if enabled
                if addWatermark && !watermarkText.isEmpty {
                    let watermarkService = WatermarkServiceImpl()
                    let style = WatermarkStyle.from(fontSize: watermarkFontSize, opacity: watermarkOpacity, spacing: watermarkSpacing)
                    if let watermarkedImage = watermarkService.applyWatermark(to: image, text: watermarkText, style: style) {
                        processedImages.append(watermarkedImage)
                    } else {
                        processedImages.append(image)
                    }
                } else {
                    processedImages.append(image)
                }
            }

            await MainActor.run {
                self.previewImages = processedImages
                self.isLoadingPreview = false
                self.selectedPreviewIndex = 0
            }
        } catch {
            await MainActor.run {
                self.isLoadingPreview = false
            }
        }
    }
}

// MARK: - Export Single Image Sheet

struct ExportSingleImageSheet: View {
    let attachmentId: UUID
    let fileName: String
    @Environment(\.dismiss) private var dismiss
    @State private var watermarkText: String = ""
    @State private var addWatermark: Bool = true
    @State private var watermarkFontSize: Double = 30  // 字号范围 20-80
    @State private var watermarkSpacing: WatermarkSpacing = .normal  // 行间距
    @State private var watermarkOpacity: Double = 0.3
    @State private var enableAdvancedOptions: Bool = false
    @State private var maxWidth: String = ""
    @State private var maxHeight: String = ""
    @State private var maxFileSize: String = ""
    @State private var isExporting = false
    @State private var showToast = false
    @State private var toastMessage = ""
    @State private var previewImage: UIImage?
    @State private var isLoadingPreview = false

    var body: some View {
        NavigationStack {
            Form {
                // Preview Section at top
                if let previewImage = previewImage {
                    Section {
                        Image(uiImage: previewImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } header: {
                        Text("export.preview".localized)
                    }
                    .listRowSpacing(8)
                } else if isLoadingPreview {
                    Section {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .frame(height: 200)
                    } header: {
                        Text("export.preview".localized)
                    }
                    .listRowSpacing(8)
                }

                Section {
                    Toggle("export.add.watermark".localized, isOn: $addWatermark)

                    if addWatermark {
                        TextField("export.watermark.placeholder".localized, text: $watermarkText)
                            .textFieldStyle(.roundedBorder)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("export.watermark.fontsize".localized)
                                Spacer()
                                Text("\(Int(watermarkFontSize))")
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $watermarkFontSize, in: 20...80, step: 1)
                        }

                        Picker("export.watermark.spacing".localized, selection: $watermarkSpacing) {
                            ForEach(WatermarkSpacing.allCases) { spacing in
                                Text(spacing.displayName).tag(spacing)
                            }
                        }
                        .pickerStyle(.segmented)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("export.watermark.opacity".localized)
                                Spacer()
                                Text("\(Int(watermarkOpacity * 100))%")
                                    .foregroundStyle(.secondary)
                            }
                            Slider(value: $watermarkOpacity, in: 0.1...1.0, step: 0.05)
                        }
                    }
                } header: {
                    Text("export.watermark.title".localized)
                } footer: {
                    Text("export.watermark.hint".localized)
                        .font(.caption)
                }
                .listRowSpacing(6)

                Section {
                    Toggle("export.advanced.options".localized, isOn: $enableAdvancedOptions)

                    if enableAdvancedOptions {
                        HStack {
                            Text("export.max.width".localized)
                            Spacer()
                            TextField("export.pixel".localized, text: $maxWidth)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }

                        HStack {
                            Text("export.max.height".localized)
                            Spacer()
                            TextField("export.pixel".localized, text: $maxHeight)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }

                        HStack {
                            Text("export.max.filesize".localized)
                            Spacer()
                            TextField("KB", text: $maxFileSize)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }
                    }
                } header: {
                    Text("export.size.compression".localized)
                } footer: {
                    if enableAdvancedOptions {
                        Text("export.hint.limits".localized)
                            .font(.caption)
                    }
                }
                .listRowSpacing(6)

                Section {
                    Button {
                        Task {
                            await exportImage()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isExporting {
                                ProgressView()
                                    .padding(.trailing, 8)
                            }
                            Text("export.action".localized)
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(isExporting)
                }
                .listRowSpacing(6)
            }
            .navigationTitle("export.image".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .task {
            await generatePreview()
        }
        .onChange(of: addWatermark) { _, _ in
            Task { await generatePreview() }
        }
        .onChange(of: watermarkText) { _, _ in
            Task { await generatePreview() }
        }
        .onChange(of: watermarkFontSize) { _, _ in
            Task { await generatePreview() }
        }
        .onChange(of: watermarkSpacing) { _, _ in
            Task { await generatePreview() }
        }
        .onChange(of: watermarkOpacity) { _, _ in
            Task { await generatePreview() }
        }
        .overlay {
            if showToast {
                ToastView(message: toastMessage)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showToast = false
                        }
                    }
            }
        }
    }

    private func exportImage() async {
        isExporting = true

        do {
            let attachmentService = AttachmentServiceImpl.shared
            let watermark = addWatermark && !watermarkText.isEmpty ? watermarkText : nil

            // Build export options
            let exportOptions = ImageExportOptions(
                maxWidth: maxWidth.isEmpty ? nil : CGFloat(Int(maxWidth) ?? 0),
                maxHeight: maxHeight.isEmpty ? nil : CGFloat(Int(maxHeight) ?? 0),
                maxFileSizeKB: maxFileSize.isEmpty ? nil : Int(maxFileSize),
                jpegQuality: 0.9
            )

            let url = try await attachmentService.shareAttachment(
                id: attachmentId,
                watermarkText: watermark,
                watermarkFontSize: watermarkFontSize,
                watermarkSpacing: watermarkSpacing,
                watermarkOpacity: watermarkOpacity,
                exportOptions: exportOptions
            )

            // Present share sheet
            await MainActor.run {
                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

                activityVC.completionWithItemsHandler = { [self] activityType, completed, returnedItems, error in
                    Task { @MainActor in
                        if let error = error {
                            toastMessage = "export.failed".localized + ": \(error.localizedDescription)"
                            showToast = true
                        } else if completed {
                            toastMessage = "export.success".localized
                            showToast = true
                            // Close the sheet after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                dismiss()
                            }
                        }
                    }
                }

                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first?.rootViewController {
                    var presentingVC = rootVC
                    while let presented = presentingVC.presentedViewController {
                        presentingVC = presented
                    }
                    presentingVC.present(activityVC, animated: true)
                }
            }
        } catch {
            toastMessage = "export.failed".localized + ": \(error.localizedDescription)"
            showToast = true
        }

        isExporting = false
    }

    private func generatePreview() async {
        await MainActor.run {
            isLoadingPreview = true
        }

        do {
            let attachmentService = AttachmentServiceImpl.shared
            let data = try await attachmentService.getAttachmentData(id: attachmentId)

            guard let image = UIImage(data: data) else {
                await MainActor.run {
                    isLoadingPreview = false
                }
                return
            }

            // Apply watermark if enabled
            if addWatermark && !watermarkText.isEmpty {
                let watermarkService = WatermarkServiceImpl()
                let style = WatermarkStyle.from(fontSize: watermarkFontSize, opacity: watermarkOpacity, spacing: watermarkSpacing)
                if let watermarkedImage = watermarkService.applyWatermark(to: image, text: watermarkText, style: style) {
                    await MainActor.run {
                        self.previewImage = watermarkedImage
                        self.isLoadingPreview = false
                    }
                } else {
                    await MainActor.run {
                        self.previewImage = image
                        self.isLoadingPreview = false
                    }
                }
            } else {
                // Show original image
                await MainActor.run {
                    self.previewImage = image
                    self.isLoadingPreview = false
                }
            }
        } catch {
            await MainActor.run {
                self.isLoadingPreview = false
            }
        }
    }
}

// MARK: - Image Preview Sheet

struct ImagePreviewSheet: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView([.horizontal, .vertical]) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            minWidth: geometry.size.width,
                            minHeight: geometry.size.height
                        )
                }
            }
            .navigationTitle("export.preview".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Multiple Images Preview Sheet

struct MultipleImagesPreviewSheet: View {
    let images: [UIImage]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedIndex = 0

    var body: some View {
        NavigationStack {
            VStack {
                TabView(selection: $selectedIndex) {
                    ForEach(images.indices, id: \.self) { index in
                        GeometryReader { geometry in
                            ScrollView([.horizontal, .vertical]) {
                                Image(uiImage: images[index])
                                    .resizable()
                                    .scaledToFit()
                                    .frame(
                                        minWidth: geometry.size.width,
                                        minHeight: geometry.size.height
                                    )
                            }
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))

                Text("\(selectedIndex + 1) / \(images.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
            .navigationTitle("export.preview".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.close".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        CardDetailView(cardId: UUID())
    }
}
