import PhotosUI
import SwiftUI
import QuickVaultCore

/// Card editor sheet / 卡片编辑表单
struct CardEditorSheet: View {
    @StateObject private var viewModel: CardEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Photo upload states for different document sides
    @State private var frontPhotoItem: PhotosPickerItem?
    @State private var backPhotoItem: PhotosPickerItem?
    @State private var frontImage: UIImage?
    @State private var backImage: UIImage?
    
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
                                ForEach(CardEditorViewModel.CardType.allCases) { type in
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
                if viewModel.supportsOCR && !viewModel.isEditing {
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
                                    await viewModel.recognizeAndFillFromImage(image)
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
                                        await viewModel.recognizeAndFillFromImage(image)
                                    }
                                    backPhotoItem = nil
                                }
                            }
                        }
                    } header: {
                        Text("ocr.photo.upload".localized)
                    } footer: {
                        Text(viewModel.selectedType.photoUploadHint)
                            .font(.caption)
                    }
                }
                
                if let error = viewModel.validationErrors["title"] {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
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
                            
                            if field.label.contains("备注") || field.label.contains("Notes") || 
                               field.label.contains("内容") || field.label.contains("Content") ||
                               field.label.contains("详细地址") || field.label.contains("Address") {
                                TextEditor(text: $field.value)
                                    .frame(minHeight: 80)
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
                        TextField("cards.tags.add".localized, text: $viewModel.newTag)
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
            .onAppear {
                if let card = editingCard {
                    viewModel.setupForEditing(card: card)
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

// MARK: - CardType Photo Properties Extension

extension CardEditorViewModel.CardType {
    /// 是否有背面（需要上传两张照片）
    var hasBackSide: Bool {
        switch self {
        case .idCard:
            return true  // 中国身份证需要正反面
        case .passport, .businessLicense:
            return false  // 护照和营业执照只需要一面
        default:
            return false
        }
    }
    
    /// 正面照片标签
    var frontPhotoLabel: String {
        switch self {
        case .idCard:
            return "ocr.idcard.front".localized
        case .passport:
            return "ocr.passport.datapage".localized
        case .businessLicense:
            return "ocr.license.photo".localized
        default:
            return "ocr.photo.front".localized
        }
    }
    
    /// 背面照片标签
    var backPhotoLabel: String {
        switch self {
        case .idCard:
            return "ocr.idcard.back".localized
        default:
            return "ocr.photo.back".localized
        }
    }
    
    /// 照片上传提示
    var photoUploadHint: String {
        switch self {
        case .idCard:
            return "ocr.hint.idcard".localized
        case .passport:
            return "ocr.hint.passport".localized
        case .businessLicense:
            return "ocr.hint.license".localized
        default:
            return ""
        }
    }
}

#Preview {
    CardEditorSheet(onSave: {})
}
