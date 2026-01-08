import SwiftUI
import QuickVaultCore

/// Card editor sheet / 卡片编辑表单
struct CardEditorSheet: View {
    @StateObject private var viewModel: CardEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    let editingCard: CardDTO?
    let onSave: () -> Void
    
    init(editingCard: CardDTO? = nil, onSave: @escaping () -> Void) {
        self.editingCard = editingCard
        self.onSave = onSave
        
        let persistenceController = PersistenceController.shared
        let cryptoService = CryptoServiceImpl()
        let cardService = CardServiceImpl(persistenceController: persistenceController, cryptoService: cryptoService)
        _viewModel = StateObject(wrappedValue: CardEditorViewModel(cardService: cardService))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Basic Info Section
                Section {
                    TextField("标题 / Title", text: $viewModel.title)
                    
                    if !viewModel.isEditing {
                        Picker("类型 / Type", selection: $viewModel.selectedType) {
                            ForEach(CardEditorViewModel.CardType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .onChange(of: viewModel.selectedType) { _, newType in
                            viewModel.setupFieldsForType(newType)
                        }
                    }
                    
                    Picker("分组 / Group", selection: $viewModel.selectedGroup) {
                        ForEach(Array(zip(viewModel.groupOptions, viewModel.groupDisplayNames)), id: \.0) { option, displayName in
                            Text(displayName).tag(option)
                        }
                    }
                } header: {
                    Text("基本信息 / Basic Info")
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
                    Text("字段 / Fields")
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
                        TextField("添加标签 / Add Tag", text: $viewModel.newTag)
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
                    Text("标签 / Tags")
                }
                
                // Error Message
                if let error = viewModel.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "编辑卡片 / Edit Card" : "新建卡片 / New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消 / Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存 / Save") {
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

#Preview {
    CardEditorSheet(onSave: {})
}
