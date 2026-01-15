import SwiftUI
import PhotosUI
import QuickHoldCore

/// 卡片创建向导 - 两步流程 / Card Creation Wizard - Two-Step Flow
struct CardCreationWizard: View {
    @StateObject private var viewModel: CardEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep: CreationStep = .typeAndPhoto
    @State private var selectedType: CardType = .idCard
    @State private var frontPhotoItem: PhotosPickerItem?
    @State private var backPhotoItem: PhotosPickerItem?
    @State private var frontImage: UIImage?
    @State private var backImage: UIImage?
    @State private var isProcessingOCR = false
    @State private var ocrError: String?
    
    let onSave: () -> Void
    
    enum CreationStep {
        case typeAndPhoto  // 第一步：类型选择 + 照片上传
        case formEditing   // 第二步：表单编辑
    }
    
    init(onSave: @escaping () -> Void) {
        self.onSave = onSave
        
        let persistenceController = PersistenceController.shared
        let cardService = CardServiceImpl(persistenceController: persistenceController, cryptoService: CryptoServiceImpl.shared)
        _viewModel = StateObject(wrappedValue: CardEditorViewModel(cardService: cardService))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch currentStep {
                case .typeAndPhoto:
                    typeAndPhotoSelectionView
                case .formEditing:
                    formEditingView
                }
            }
            .navigationTitle(currentStep == .typeAndPhoto ? "新建卡片 / New Card" : "填写信息 / Edit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消 / Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.setupForNewCard(type: selectedType)
        }
    }
    
    // MARK: - Step 1: Type and Photo Selection
    
    private var typeAndPhotoSelectionView: some View {
        VStack(spacing: 0) {
            // 类型选择区域
            VStack(alignment: .leading, spacing: 12) {
                Text("选择卡片类型 / Select Card Type")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(CardType.allCases) { type in
                            CardTypeButton(
                                type: type,
                                isSelected: selectedType == type
                            ) {
                                selectedType = type
                                viewModel.setupFieldsForType(type)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
            .padding(.vertical)
            .background(Color(.systemGroupedBackground))
            
            Divider()
            
            // 照片上传区域
            ScrollView {
                VStack(spacing: 20) {
                    // 提示信息
                    if !selectedType.photoUploadHint.isEmpty {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                            Text(selectedType.photoUploadHint)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    
                    // 正面照片上传
                    PhotoUploadCard(
                        title: selectedType.frontPhotoLabel,
                        image: $frontImage,
                        photoItem: $frontPhotoItem,
                        isRequired: true
                    )
                    
                    // 背面照片上传（如果需要）
                    if selectedType.hasBackSide {
                        PhotoUploadCard(
                            title: selectedType.backPhotoLabel,
                            image: $backImage,
                            photoItem: $backPhotoItem,
                            isRequired: false
                        )
                    }
                    
                    // 错误提示
                    if let error = ocrError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    
                    // 下一步按钮
                    Button(action: proceedToFormEditing) {
                        HStack {
                            if isProcessingOCR {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isProcessingOCR ? "识别中 / Processing..." : "下一步：填写信息 / Next: Edit Details")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canProceed ? Color.accentColor : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!canProceed || isProcessingOCR)
                }
                .padding()
            }
        }
        .onChange(of: frontPhotoItem) { _, newItem in
            Task {
                await loadFrontImage(from: newItem)
            }
        }
        .onChange(of: backPhotoItem) { _, newItem in
            Task {
                await loadBackImage(from: newItem)
            }
        }
    }
    
    // MARK: - Step 2: Form Editing
    
    private var formEditingView: some View {
        Form {
            // 标题
            Section {
                TextField("标题 / Title", text: $viewModel.title)
            } header: {
                Text("基本信息 / Basic Info")
            }
            
            // 分组
            Section {
                Picker("分组 / Group", selection: $viewModel.selectedGroup) {
                    ForEach(viewModel.groupOptions.indices, id: \.self) { index in
                        Text(viewModel.groupDisplayNames[index])
                            .tag(viewModel.groupOptions[index])
                    }
                }
            }
            
            // 字段
            Section {
                ForEach($viewModel.fields) { $field in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(field.label)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            if field.isRequired {
                                Text("*")
                                    .foregroundStyle(.red)
                            }
                        }
                        
                        if field.isMultiline {
                            TextEditor(text: $field.value)
                                .frame(minHeight: 80)
                        } else {
                            TextField("", text: $field.value)
                        }
                        
                        if let error = viewModel.validationErrors[field.label] {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
            } header: {
                Text("字段信息 / Fields")
            }
            
            // 照片预览
            Section {
                if let frontImage = frontImage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedType.frontPhotoLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Image(uiImage: frontImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    }
                }
                
                if let backImage = backImage {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(selectedType.backPhotoLabel)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Image(uiImage: backImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                    }
                }
            } header: {
                Text("附件预览 / Attachments")
            }
            
            // 操作按钮
            Section {
                Button(action: {
                    currentStep = .typeAndPhoto
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("返回上一步 / Back")
                    }
                }
                
                Button(action: saveCard) {
                    HStack {
                        Spacer()
                        Text("保存卡片 / Save Card")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
                .disabled(!viewModel.isValid)
            }
        }
    }
    
    // MARK: - Helper Views
    
    private var canProceed: Bool {
        frontImage != nil
    }
    
    // MARK: - Actions
    
    private func loadFrontImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    frontImage = image
                }
            }
        } catch {
            print("Error loading front image: \(error)")
        }
    }
    
    private func loadBackImage(from item: PhotosPickerItem?) async {
        guard let item = item else { return }
        
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    backImage = image
                }
            }
        } catch {
            print("Error loading back image: \(error)")
        }
    }
    
    private func proceedToFormEditing() {
        Task {
            await performOCRAndProceed()
        }
    }
    
    private func performOCRAndProceed() async {
        guard let frontImage = frontImage else { return }
        
        await MainActor.run {
            isProcessingOCR = true
            ocrError = nil
        }
        
        // 保存照片到 ViewModel
        await MainActor.run {
            viewModel.frontPhoto = frontImage
            viewModel.backPhoto = backImage
        }
        
        // 执行OCR识别
        do {
            let ocrService = OCRServiceImpl.shared
            let result = try await ocrService.recognizeDocument(image: frontImage)
            
            // 将OCR结果填充到字段
            await MainActor.run {
                let cardFields = result.toCardFields()
                print("  📋 [OCR填充] 识别到的字段: \(cardFields)")
                print("  📝 [OCR填充] 当前表单字段标签: \(viewModel.fields.map { $0.label })")
                
                // 使用 fillFieldsFromOCR 方法（私有方法，需要通过normalizeFields调用）
                // 直接填充字段
                for i in 0..<viewModel.fields.count {
                    let label = viewModel.fields[i].label
                    // 匹配字段标签与OCR键
                    for (key, value) in cardFields {
                        if label.lowercased().contains(key.lowercased()) || 
                           key.lowercased().contains(label.replacingOccurrences(of: " ", with: "").lowercased()) {
                            viewModel.fields[i].value = value
                            print("    ✓ [OCR填充] 通用匹配: \(label) = \(value)")
                            break
                        }
                        // 特殊匹配规则
                        if (key == "name" && (label.contains("姓名") || label.contains("Name"))) ||
                           (key == "passportNumber" && (label.contains("护照号") || label.contains("Passport"))) ||
                           (key == "nationality" && (label.contains("国籍") || label.contains("Nationality"))) ||
                           (key == "birthDate" && (label.contains("出生") || label.contains("Birth"))) ||
                           (key == "issueDate" && (label.contains("签发日期") || label.contains("Issue Date") || label.contains("Date of Issue"))) ||
                           (key == "expiryDate" && (label.contains("有效期") || label.contains("Expiry"))) ||
                           (key == "issuePlace" && (label.contains("签发地点") || label.contains("Issue Place") || label.contains("Place of Issue"))) ||
                           (key == "issuer" && (label.contains("签发机关") || label.contains("Issuer") || label.contains("Authority") || label.contains("Issuing Authority"))) ||
                           (key == "gender" && (label.contains("性别") || label.contains("Sex") || label.contains("Gender"))) {
                            viewModel.fields[i].value = value
                            print("    ✓ [OCR填充] 特殊匹配: \(label) = \(value)")
                            break
                        }
                    }
                }
                
                // 自动生成标题（如果OCR识别到姓名）
                if let nameValue = cardFields.first(where: { key, _ in 
                    key.contains("姓名") || key.contains("Name") || key.contains("name")
                })?.value {
                    if viewModel.title.isEmpty {
                        viewModel.title = "\(selectedType.displayName) - \(nameValue)"
                    }
                }
                
                isProcessingOCR = false
                currentStep = .formEditing
            }
        } catch {
            await MainActor.run {
                isProcessingOCR = false
                ocrError = "识别失败，将使用空白表单 / OCR failed, will use blank form"
                
                // 即使OCR失败，也允许进入下一步
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    currentStep = .formEditing
                }
            }
        }
    }
    
    private func saveCard() {
        Task {
            if await viewModel.saveCard() != nil {
                await MainActor.run {
                    onSave()
                    dismiss()
                }
            } else if let errorMessage = viewModel.errorMessage {
                print("Save error: \(errorMessage)")
            }
        }
    }
}

// MARK: - Supporting Views

struct CardTypeButton: View {
    let type: CardType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconForType(type))
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? .white : .primary)
                
                Text(type.displayName)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(width: 90, height: 90)
            .background(isSelected ? Color.accentColor : Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: isSelected ? .accentColor.opacity(0.3) : .clear, radius: 8)
        }
    }
    
    private func iconForType(_ type: CardType) -> String {
        switch type {
        case .idCard: return "person.text.rectangle"
        case .passport: return "book.closed"
        case .driversLicense: return "car"
        case .residencePermit: return "house.and.flag"
        case .socialSecurityCard: return "heart.text.square"
        case .bankCard: return "creditcard"
        case .businessLicense: return "building.2"
        case .invoice: return "doc.text"
        case .address: return "mappin.and.ellipse"
        default: return "doc"
        }
    }
}

struct PhotoUploadCard: View {
    let title: String
    @Binding var image: UIImage?
    @Binding var photoItem: PhotosPickerItem?
    let isRequired: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if isRequired {
                    Text("*")
                        .foregroundStyle(.red)
                }
            }
            
            if let image = image {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 200)
                        .cornerRadius(12)
                    
                    Button(action: {
                        self.image = nil
                        self.photoItem = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                            .background(Circle().fill(Color.black.opacity(0.6)))
                    }
                    .padding(8)
                }
            } else {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        
                        Text("点击选择照片 / Tap to select photo")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 150)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundStyle(.secondary.opacity(0.3))
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

// MARK: - ViewModel Extension

extension CardEditorViewModel {
    /// 从OCR结果填充字段
    func populateFieldsFromOCR(_ ocrFields: [String: String]) {
        for (label, value) in ocrFields {
            // 查找匹配的字段（通过标签模糊匹配）
            if let index = fields.firstIndex(where: { field in
                field.label.contains(label) || 
                label.contains(field.label.split(separator: "/").first?.trimmingCharacters(in: .whitespaces) ?? "")
            }) {
                fields[index].value = value
            }
        }
    }
}
