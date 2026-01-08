import SwiftUI
import Combine
import QuickVaultCore

enum CardEditorMode {
  case new
  case edit(CardDTO)

  var existingCard: CardDTO? {
    switch self {
    case .new: return nil
    case .edit(let card): return card
    }
  }

  var isEdit: Bool {
    if case .edit = self { return true }
    return false
  }
}

struct CardEditorSubmission {
  let mode: CardEditorMode
  let title: String
  let group: String
  let tags: [String]
  let type: CardType
  let fieldValues: [String: String]
  let isPinned: Bool
}

final class CardEditorState: ObservableObject {
  @Published var title: String
  @Published var group: String
  @Published var tagsInput: String
  @Published var templateType: CardType
  @Published var isPinned: Bool
  @Published var fieldValues: [String: String]
  @Published var fieldValidationStates: [String: FieldValidationState] = [:]

  let mode: CardEditorMode

  init(mode: CardEditorMode) {
    self.mode = mode
    let card = mode.existingCard
    let initialType: CardType = {
      if let card, let type = CardType(rawValue: card.type) {
        return type
      }
      return .general
    }()
    let templateFields = CardTemplateHelper.fields(for: initialType)
    let initialValues: [String: String]
    if let card {
      initialValues = CardEditorState.values(for: card, templateFields: templateFields)
    } else {
      initialValues = Dictionary(uniqueKeysWithValues: templateFields.map { ($0.key, "") })
    }

    self.title = card?.title ?? ""
    self.group = card?.group ?? ""
    self.tagsInput = card?.tags.joined(separator: ", ") ?? ""
    self.isPinned = card?.isPinned ?? false
    self.templateType = initialType
    self.fieldValues = initialValues
  }

  var isEdit: Bool { mode.isEdit }

  var templateFields: [FieldDefinition] {
    CardTemplateHelper.fields(for: templateType)
  }

  func syncFieldValues(for newType: CardType) {
    let fields = CardTemplateHelper.fields(for: newType)
    var updated: [String: String] = [:]
    for field in fields {
      updated[field.key] = fieldValues[field.key] ?? ""
    }
    fieldValues = updated
    fieldValidationStates.removeAll()
  }

  func normalizedTags() -> [String] {
    tagsInput
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
  }

  func resolvedGroup() -> String {
    let trimmed = group.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? CardGroup.personal.rawValue : trimmed
  }

  func trimmedTitle() -> String {
    title.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func submission() -> CardEditorSubmission {
    CardEditorSubmission(
      mode: mode,
      title: trimmedTitle(),
      group: resolvedGroup(),
      tags: normalizedTags(),
      type: templateType,
      fieldValues: fieldValues,
      isPinned: isPinned
    )
  }

  private static func values(
    for card: CardDTO,
    templateFields: [FieldDefinition]
  ) -> [String: String] {
    var values: [String: String] = [:]
    for fieldDef in templateFields {
      if let match = card.fields.first(where: { $0.label == fieldDef.label }) {
        values[fieldDef.key] = match.value
      } else {
        values[fieldDef.key] = ""
      }
    }
    return values
  }
}

struct CardEditorView: View {
  @ObservedObject var state: CardEditorState
  let onSave: (CardEditorSubmission) async throws -> Void
  let onCancel: () -> Void

  @State private var errorMessage: String?
  @State private var isSaving = false
  @State private var showContent = false

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Card Type Selection (now at top, more prominent)
        CardTypePickerView(
          selectedType: $state.templateType,
          isDisabled: state.isEdit
        )
        .onChange(of: state.templateType) { oldValue, newType in
          withAnimation {
            state.syncFieldValues(for: newType)
          }
        }

        Divider()

        // Basic Information Section
        VStack(alignment: .leading, spacing: 16) {
          SectionHeader(title: "基本信息", icon: "info.circle.fill")

          StyledTextField(
            label: "卡片标题",
            placeholder: "例如：家庭地址、公司发票",
            text: $state.title,
            isRequired: true,
            validationState: titleValidationState
          )

          // Group Picker
          VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
              Text("分组")
                .font(.system(.body, design: .default))
                .fontWeight(.medium)
                .foregroundColor(.primary)
            }

            Picker("", selection: $state.group) {
              Text("个人").tag(CardGroup.personal.rawValue)
              Text("公司").tag(CardGroup.company.rawValue)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
          }

          TagInputView(tagsInput: $state.tagsInput)

          Toggle(isOn: $state.isPinned) {
            HStack(spacing: 6) {
              Image(systemName: "pin.fill")
                .font(.caption)
                .foregroundColor(.accentColor)
              Text("置顶此卡片")
                .font(.body)
            }
          }
          .toggleStyle(.switch)
        }

        Divider()

        // Fields Section
        VStack(alignment: .leading, spacing: 16) {
          SectionHeader(
            title: "字段信息",
            icon: "list.bullet.rectangle",
            subtitle: "根据卡片类型填写对应信息"
          )

          ForEach(state.templateFields, id: \.key) { field in
            StyledTextField(
              label: field.label,
              placeholder: placeholderText(for: field),
              text: binding(for: field.key),
              isRequired: field.required,
              validationState: state.fieldValidationStates[field.key] ?? .normal,
              multiline: field.multiline
            )
          }
        }

        // Action Buttons
        HStack(spacing: 12) {
          Button(action: onCancel) {
            HStack {
              Image(systemName: "xmark")
              Text("取消")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
          }
          .buttonStyle(.plain)
          .background(Color.secondary.opacity(0.1))
          .cornerRadius(8)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
          )

          Button(action: save) {
            HStack {
              if isSaving {
                ProgressView()
                  .scaleEffect(0.8)
                  .frame(width: 16, height: 16)
              } else {
                Image(systemName: state.isEdit ? "checkmark" : "plus")
              }
              Text(state.isEdit ? "保存" : "创建")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
          }
          .buttonStyle(.plain)
          .background(Color.accentColor)
          .foregroundColor(.white)
          .cornerRadius(8)
          .disabled(isSaving)
          .keyboardShortcut(.defaultAction)
        }
        .padding(.top, 8)
      }
      .padding(24)
    }
    .frame(minWidth: 640, minHeight: 700)
    .background(
      ZStack {
        // Base background
        Color(NSColor.windowBackgroundColor)
        
        // Subtle gradient overlay based on card type
        LinearGradient(
          colors: gradientColorsForType(state.templateType),
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
        .opacity(0.08)
        .ignoresSafeArea()
      }
    )
    .opacity(showContent ? 1.0 : 0.0)
    .offset(y: showContent ? 0 : 20)
    .onAppear {
      withAnimation(.easeOut(duration: 0.3)) {
        showContent = true
      }
    }
    .alert("无法保存", isPresented: Binding(
      get: { errorMessage != nil },
      set: { if !$0 { errorMessage = nil } }
    )) {
      Button("好的", role: .cancel) {}
    } message: {
      Text(errorMessage ?? "")
    }
  }

  private func gradientColorsForType(_ type: CardType) -> [Color] {
    switch type {
    case .general:
      return [Color(red: 0.4, green: 0.6, blue: 1.0), Color(red: 0.6, green: 0.4, blue: 1.0)]
    case .address:
      return [Color(red: 1.0, green: 0.4, blue: 0.5), Color(red: 1.0, green: 0.6, blue: 0.3)]
    case .invoice:
      return [Color(red: 0.2, green: 0.8, blue: 0.6), Color(red: 0.3, green: 0.9, blue: 0.8)]
    case .businessLicense:
      return [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 1.0, green: 0.8, blue: 0.3)]
    case .idCard:
      return [Color(red: 0.5, green: 0.4, blue: 1.0), Color(red: 0.7, green: 0.5, blue: 1.0)]
    }
  }

  private var titleValidationState: FieldValidationState {
    if state.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      return .normal
    }
    return .success
  }

  private func binding(for key: String) -> Binding<String> {
    Binding(
      get: { state.fieldValues[key] ?? "" },
      set: { state.fieldValues[key] = $0 }
    )
  }

  private func placeholderText(for field: FieldDefinition) -> String {
    switch field.key {
    case "recipient": return "收件人姓名"
    case "phone": return "13800138000"
    case "province": return "北京市"
    case "city": return "北京市"
    case "district": return "朝阳区"
    case "address": return "详细街道地址"
    case "postalCode": return "100000"
    case "companyName": return "公司全称"
    case "taxId": return "18位统一社会信用代码"
    case "bankName": return "开户银行名称"
    case "bankAccount": return "银行账号"
    case "content": return "输入任意文本内容..."
    case "notes": return "可选备注信息"
    default: return "请输入" + field.label
    }
  }

  private func save() {
    let validator = ValidationServiceImpl()
    let submission = state.submission()

    // Reset validation states
    state.fieldValidationStates.removeAll()

    // Validate title
    guard !submission.title.isEmpty else {
      errorMessage = "卡片标题不能为空"
      return
    }

    // Validate fields
    do {
      try validator.validateCardFields(submission.fieldValues, for: state.templateFields)
      // Set success states for validated fields
      for field in state.templateFields where field.required {
        if let value = submission.fieldValues[field.key], !value.isEmpty {
          state.fieldValidationStates[field.key] = .success
        }
      }
    } catch {
      // Set error states
      if let validationError = error as? ValidationError {
        handleValidationError(validationError)
      }
      errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
      return
    }

    isSaving = true
    Task {
      do {
        try await onSave(submission)
        await MainActor.run {
          isSaving = false
          onCancel()
        }
      } catch CryptoError.keyNotAvailable {
        await MainActor.run {
          isSaving = false
          errorMessage = "加密密钥不可用，请先设置主密码或解锁应用\n\nEncryption key not available. Please set up your master password or unlock the app first."
        }
      } catch {
        await MainActor.run {
          isSaving = false
          errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
      }
    }
  }

  private func handleValidationError(_ error: ValidationError) {
    switch error {
    case .invalidPhoneNumber:
      state.fieldValidationStates["phone"] = .error("无效的电话号码格式")
    case .invalidTaxID:
      state.fieldValidationStates["taxId"] = .error("无效的税号格式")
    case .requiredFieldEmpty(let fieldName):
      // Find the field key for this label
      if let field = state.templateFields.first(where: { $0.label == fieldName }) {
        state.fieldValidationStates[field.key] = .error("此字段为必填项")
      }
    default:
      break
    }
  }
}

// MARK: - Section Header Component

struct SectionHeader: View {
  let title: String
  let icon: String
  var subtitle: String? = nil

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 8) {
        ZStack {
          Circle()
            .fill(
              LinearGradient(
                colors: [Color.accentColor.opacity(0.2), Color.purple.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 28, height: 28)
          
          Image(systemName: icon)
            .font(.system(.body, weight: .semibold))
            .foregroundStyle(
              LinearGradient(
                colors: [Color.accentColor, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
        }
        
        Text(title)
          .font(.headline)
          .fontWeight(.semibold)
      }

      if let subtitle = subtitle {
        Text(subtitle)
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
  }
}
