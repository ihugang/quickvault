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
                    TextField("cards.title.placeholder".localized, text: $viewModel.title)
                    
                    if !viewModel.isEditing {
                        Picker("cards.type.general".localized, selection: $viewModel.selectedType) {
                            ForEach(CardEditorViewModel.CardType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .onChange(of: viewModel.selectedType) { _, newType in
                            viewModel.setupFieldsForType(newType)
                        }
                    }
                    
                    Picker("cards.group.placeholder".localized, selection: $viewModel.selectedGroup) {
                        ForEach(Array(zip(viewModel.groupOptions, viewModel.groupDisplayNames)), id: \.0) { option, displayName in
                            Text(displayName).tag(option)
                        }
                    }
                } header: {
                    Text("cards.field.label".localized)
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

#Preview {
    CardEditorSheet(onSave: {})
}
