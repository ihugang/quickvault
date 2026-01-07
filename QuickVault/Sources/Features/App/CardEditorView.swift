import SwiftUI
import Combine

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

  var body: some View {
    VStack(spacing: 16) {
      Form {
        Section("Basics") {
          TextField("Title", text: $state.title)
          TextField("Group (personal/company)", text: $state.group)
          TextField("Tags (comma-separated)", text: $state.tagsInput)

          Picker("Template", selection: $state.templateType) {
            ForEach(CardType.allCases, id: \.self) { type in
              Text(type.displayName).tag(type)
            }
          }
          .disabled(state.isEdit)

          Toggle("Pinned", isOn: $state.isPinned)
        }

        Section("Fields") {
          ForEach(state.templateFields, id: \.key) { field in
            VStack(alignment: .leading, spacing: 6) {
              HStack(spacing: 6) {
                Text(field.label)
                if !field.required {
                  Text("Optional")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              }

              if field.multiline {
                TextEditor(text: binding(for: field.key))
                  .frame(minHeight: 80)
                  .overlay(
                    RoundedRectangle(cornerRadius: 6)
                      .stroke(Color.secondary.opacity(0.4), lineWidth: 1)
                  )
              } else {
                TextField("", text: binding(for: field.key))
                  .textFieldStyle(.roundedBorder)
              }
            }
            .padding(.vertical, 4)
          }
        }
      }
      .onChange(of: state.templateType) { newType in
        state.syncFieldValues(for: newType)
      }

      HStack {
        Button("Cancel") {
          onCancel()
        }
        Spacer()
        Button(state.isEdit ? "Save" : "Create") {
          save()
        }
        .keyboardShortcut(.defaultAction)
        .disabled(isSaving)
      }
    }
    .padding(20)
    .frame(minWidth: 440, minHeight: 520)
    .alert("Unable to Save", isPresented: Binding(
      get: { errorMessage != nil },
      set: { if !$0 { errorMessage = nil } }
    )) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(errorMessage ?? "")
    }
  }

  private func binding(for key: String) -> Binding<String> {
    Binding(
      get: { state.fieldValues[key] ?? "" },
      set: { state.fieldValues[key] = $0 }
    )
  }

  private func save() {
    let validator = ValidationServiceImpl()
    let submission = state.submission()

    guard !submission.title.isEmpty else {
      errorMessage = "Title cannot be empty."
      return
    }

    do {
      try validator.validateCardFields(submission.fieldValues, for: state.templateFields)
    } catch {
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
      } catch {
        await MainActor.run {
          isSaving = false
          errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        }
      }
    }
  }
}
