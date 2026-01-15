import PhotosUI
import SwiftUI
import QuickHoldCore

/// Card editor sheet / 卡片编辑表单
struct CardEditorSheet: View {
    @StateObject private var viewModel: CardEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Photo upload states for different document sides
    @State private var frontPhotoItem: PhotosPickerItem?
    @State private var backPhotoItem: PhotosPickerItem?
    @State private var frontImage: UIImage?
    @State private var backImage: UIImage?
    
    // Paste text for invoice parsing
    @State private var pasteText: String = ""
    @State private var showPasteSheet: Bool = false
    
    let editingCard: CardDTO?
    let onSave: () -> Void
    
    init(editingCard: CardDTO? = nil, onSave: @escaping () -> Void) {
        self.editingCard = editingCard
        self.onSave = onSave
        
        let persistenceController = PersistenceController.shared
        let cardService = CardServiceImpl(persistenceController: persistenceController, cryptoService: CryptoServiceImpl.shared)
        _viewModel = StateObject(wrappedValue: CardEditorViewModel(cardService: cardService))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Card Type Selection - Tag Style at Top
                if !viewModel.isEditing {
                    Section {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(CardType.allCases) { type in
                                    CardTypeTag(
                                        title: type.displayName,
                                        isSelected: viewModel.selectedType == type
                                    ) {
                                        viewModel.setupFieldsForType(type)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("cards.type.select".localized)
                    }
                }
                
                // Basic Info Section
                Section {
                    TextField("cards.title.placeholder".localized, text: $viewModel.title)
                    
                    Picker("cards.group.placeholder".localized, selection: $viewModel.selectedGroup) {
                        ForEach(Array(zip(viewModel.groupOptions, viewModel.groupDisplayNames)), id: \.0) { option, displayName in
                            Text(displayName).tag(option)
                        }
                    }
                } header: {
                    Text("cards.field.label".localized)
                }
                
                // Document Photo Upload Section - 根据证件类型显示正反面上传
                if viewModel.supportsOCR {
                    Section {
                        // Front side upload
                        DocumentPhotoUploader(
                            title: viewModel.selectedType.frontPhotoLabel,
                            image: $frontImage,
                            photoItem: $frontPhotoItem,
                            isProcessing: viewModel.isOCRProcessing
                        )
                        .onChange(of: frontPhotoItem) { _, newItem in
                            Task {
                                if let newItem = newItem,
                                   let data = try? await newItem.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    frontImage = image
                                    viewModel.frontPhoto = image  // 保存到 ViewModel
                                    // 新建时：清空并重新识别；编辑时：只保存不识别
                                    if !viewModel.isEditing {
                                        await viewModel.recognizeAndFillFromImage(image, isFrontSide: true)
                                    }
                                }
                                frontPhotoItem = nil
                            }
                        }
                        
                        // Back side upload (for ID cards that need it)
                        if viewModel.selectedType.hasBackSide {
                            DocumentPhotoUploader(
                                title: viewModel.selectedType.backPhotoLabel,
                                image: $backImage,
                                photoItem: $backPhotoItem,
                                isProcessing: viewModel.isOCRProcessing,
                                isOptional: true
                            )
                            .onChange(of: backPhotoItem) { _, newItem in
                                Task {
                                    if let newItem = newItem,
                                       let data = try? await newItem.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        backImage = image
                                        viewModel.backPhoto = image  // 保存到 ViewModel
                                        // 新建时：只更新背面字段；编辑时：只保存不识别
                                        if !viewModel.isEditing {
                                            await viewModel.recognizeAndFillFromImage(image, isFrontSide: false)
                                        }
                                    }
                                    backPhotoItem = nil
                                }
                            }
                        }
                    } header: {
                        Text(viewModel.isEditing ? "attachment.document.photos".localized : "ocr.photo.upload".localized)
                    } footer: {
                        Text(viewModel.isEditing ? "ocr.edit.photo.hint".localized : viewModel.selectedType.photoUploadHint)
                            .font(.caption)
                    }
                }
                
                if let error = viewModel.validationErrors["title"] {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
                
                // Paste to Parse Section for Invoice type
                if viewModel.selectedType == .invoice {
                    Section {
                        Button {
                            showPasteSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.clipboard")
                                Text("invoice.paste.parse".localized)
                            }
                        }
                    } header: {
                        Text("invoice.paste.title".localized)
                    } footer: {
                        Text("invoice.paste.hint".localized)
                            .font(.caption)
                    }
                }
                
                // Fields Section
                Section {
                    ForEach($viewModel.fields) { $field in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(field.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                if field.isRequired {
                                    Text("*")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                            
                            if field.isMultiline {
                                TextEditor(text: $field.value)
                                    .frame(minHeight: 80)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    )
                            } else {
                                TextField(field.label, text: $field.value)
                                    .textFieldStyle(.roundedBorder)
                            }
                            
                            if let error = viewModel.validationErrors[field.id.uuidString] {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    }
                } header: {
                    Text("cards.field.add".localized)
                }
                
                // Tags Section
                Section {
                    ForEach(viewModel.tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Spacer()
                            Button {
                                viewModel.removeTag(tag)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    HStack {
                        TextField("cards.tags.add".localized, text: $viewModel.newTag, prompt: Text("输入后按回车 / Enter"))
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                            .onSubmit {
                                viewModel.addTag()
                            }
                        
                        Button {
                            viewModel.addTag()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.newTag.isEmpty)
                    }
                    .onChange(of: viewModel.newTag) { oldValue, newValue in
                        // 如果用户输入了逗号或分号，自动添加标签
                        if newValue.contains(",") || newValue.contains("，") || newValue.contains(";") || newValue.contains("；") {
                            let separator = newValue.contains(",") ? "," : 
                                          newValue.contains("，") ? "，" : 
                                          newValue.contains(";") ? ";" : "；"
                            let parts = newValue.components(separatedBy: separator)
                            
                            // 添加第一部分作为标签
                            if let first = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines), !first.isEmpty {
                                viewModel.tags.append(first)
                                // 剩余部分放回输入框
                                viewModel.newTag = parts.dropFirst().joined(separator: separator).trimmingCharacters(in: .whitespacesAndNewlines)
                            }
                        }
                    }
                } header: {
                    Text("cards.tags".localized)
                }
                
                // Error Message
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "cards.edit".localized : "cards.add".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save".localized) {
                        Task {
                            if await viewModel.saveCard() != nil {
                                onSave()
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                if let card = editingCard {
                    viewModel.setupForEditing(card: card)
                    // 加载已有的证件照片
                    await loadExistingPhotos(cardId: card.id)
                } else {
                    viewModel.setupForNewCard()
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .sheet(isPresented: $showPasteSheet) {
                InvoicePasteSheet(
                    text: $pasteText,
                    onParse: { text in
                        viewModel.parseInvoiceText(text)
                        showPasteSheet = false
                        pasteText = ""
                    }
                )
            }
        }
    }
    
    /// 加载已有的证件照片
    private func loadExistingPhotos(cardId: UUID) async {
        let attachmentService = AttachmentServiceImpl.shared
        do {
            let attachments = try await attachmentService.fetchAttachments(for: cardId)
            
            // 加载正面照片
            if let frontAttachment = attachments.first(where: { $0.fileName == viewModel.selectedType.frontPhotoFileName }) {
                let data = try await attachmentService.getAttachmentData(id: frontAttachment.id)
                if let image = UIImage(data: data) {
                    frontImage = image
                    viewModel.frontPhoto = nil  // 不重新保存已有照片
                }
            }
            
            // 加载背面照片
            if let backAttachment = attachments.first(where: { $0.fileName == viewModel.selectedType.backPhotoFileName }) {
                let data = try await attachmentService.getAttachmentData(id: backAttachment.id)
                if let image = UIImage(data: data) {
                    backImage = image
                    viewModel.backPhoto = nil  // 不重新保存已有照片
                }
            }
        } catch {
            print("Failed to load existing photos: \(error)")
        }
    }
}

// MARK: - Card Type Tag Component

struct CardTypeTag: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Document Photo Uploader Component

struct DocumentPhotoUploader: View {
    let title: String
    @Binding var image: UIImage?
    @Binding var photoItem: PhotosPickerItem?
    let isProcessing: Bool
    var isOptional: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if isOptional {
                    Text("(\("common.optional".localized))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                if isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            PhotosPicker(selection: $photoItem, matching: .images) {
                if let image = image {
                    // Show uploaded image
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.accentColor, lineWidth: 2)
                        )
                } else {
                    // Show upload placeholder
                    HStack {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                        Text("ocr.tap.upload".localized)
                            .font(.subheadline)
                    }
                    .foregroundStyle(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 80)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundStyle(.blue.opacity(0.5))
                    )
                }
            }
            .disabled(isProcessing)
        }
    }
}

// MARK: - Invoice Paste Sheet

struct InvoicePasteSheet: View {
    @Binding var text: String
    let onParse: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("invoice.paste.instruction".localized)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                
                TextEditor(text: $text)
                    .frame(minHeight: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .padding(.horizontal)
                
                Button {
                    if let clipboardText = UIPasteboard.general.string {
                        text = clipboardText
                    }
                } label: {
                    HStack {
                        Image(systemName: "doc.on.clipboard")
                        Text("invoice.paste.fromclipboard".localized)
                    }
                }
                .buttonStyle(.bordered)
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("invoice.paste.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("invoice.parse.button".localized) {
                        onParse(text)
                    }
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    CardEditorSheet(onSave: {})
}
