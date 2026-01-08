import SwiftUI
import QuickVaultCore

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
struct FlowLayout: Layout {
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
    ["IdCard", "Passport", "BusinessLicense"].contains(type)
}

// MARK: - Document Photos Section

struct DocumentPhotosSection: View {
    let cardId: UUID
    let cardType: String
    @StateObject private var viewModel: AttachmentListViewModel
    @State private var selectedAttachment: AttachmentDTO?
    
    init(cardId: UUID, cardType: String) {
        self.cardId = cardId
        self.cardType = cardType
        _viewModel = StateObject(wrappedValue: AttachmentListViewModel(cardId: cardId))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("attachment.document.photos".localized)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            if cardType == "IdCard" {
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
            } else if cardType == "Passport" {
                // 护照：信息页
                DocumentPhotoCard(
                    title: "ocr.passport.datapage".localized,
                    attachment: findAttachment(fileName: "passport_datapage.jpg"),
                    onTap: { attachment in
                        selectedAttachment = attachment
                    }
                )
            } else if cardType == "BusinessLicense" {
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
        .task {
            await viewModel.loadAttachments()
        }
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
            }
        }
    }
}

// MARK: - Attachment Preview ViewModel

@MainActor
class AttachmentPreviewViewModel: ObservableObject {
    @Published var image: UIImage?
    @Published var isLoading = true
    
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
}

#Preview {
    NavigationStack {
        CardDetailView(cardId: UUID())
    }
}
