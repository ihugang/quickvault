//
//  StyledTextField.swift
//  QuickVault
//
//  Created on 2026-01-07.
//  Styled text field with validation states and smooth transitions
//

import SwiftUI
import QuickVaultCore

/// Validation state for styled text field
enum FieldValidationState: Equatable {
  case normal
  case focused
  case error(String)
  case success
  
  var borderColor: Color {
    switch self {
    case .normal: return Color.gray.opacity(0.3)
    case .focused: return .accentColor
    case .error: return .red
    case .success: return .green
    }
  }
  
  var showIndicator: Bool {
    switch self {
    case .error, .success: return true
    default: return false
    }
  }
  
  static func == (lhs: FieldValidationState, rhs: FieldValidationState) -> Bool {
    switch (lhs, rhs) {
    case (.normal, .normal), (.focused, .focused), (.success, .success):
      return true
    case (.error(let lhsMsg), .error(let rhsMsg)):
      return lhsMsg == rhsMsg
    default:
      return false
    }
  }
}

/// Styled text field with modern macOS design and validation feedback
struct StyledTextField: View {
  let label: String
  let placeholder: String
  @Binding var text: String
  let isRequired: Bool
  let validationState: FieldValidationState
  let multiline: Bool
  
  @FocusState private var isFocused: Bool
  @State private var shouldShake = false
  
  init(
    label: String,
    placeholder: String = "",
    text: Binding<String>,
    isRequired: Bool = false,
    validationState: FieldValidationState = .normal,
    multiline: Bool = false
  ) {
    self.label = label
    self.placeholder = placeholder
    self._text = text
    self.isRequired = isRequired
    self.validationState = validationState
    self.multiline = multiline
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      // Label with required indicator
      HStack(spacing: 4) {
        Text(label)
          .font(.system(.body, design: .default))
          .fontWeight(.medium)
          .foregroundColor(.primary)
        
        if isRequired {
          Text("*")
            .foregroundColor(.red)
            .font(.system(.body, design: .default))
        } else {
          Text("可选")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(4)
        }
        
        Spacer()
        
        // Validation indicator
        if validationState.showIndicator {
          validationIndicator
        }
      }
      
      // Text input
      Group {
        if multiline {
          TextEditor(text: $text)
            .frame(minHeight: 80, maxHeight: 120)
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .overlay(
              RoundedRectangle(cornerRadius: 6)
                .stroke(currentBorderColor, lineWidth: isFocused ? 2 : 1)
            )
            .focused($isFocused)
        } else {
          TextField(placeholder, text: $text)
            .textFieldStyle(.plain)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .overlay(
              RoundedRectangle(cornerRadius: 6)
                .stroke(currentBorderColor, lineWidth: isFocused ? 2 : 1)
            )
            .focused($isFocused)
        }
      }
      .modifier(ShakeEffect(shakes: shouldShake ? 2 : 0))
      .animation(.default, value: currentBorderColor)
      
      // Error message
      if case .error(let message) = validationState {
        HStack(spacing: 4) {
          Image(systemName: "exclamationmark.circle.fill")
            .font(.caption)
          Text(message)
            .font(.caption)
        }
        .foregroundColor(.red)
        .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .onChange(of: validationState) { newState in
      if case .error = newState {
        triggerShake()
      }
    }
  }
  
  private var currentBorderColor: Color {
    if isFocused {
      return .accentColor
    }
    return validationState.borderColor
  }
  
  private var validationIndicator: some View {
    Group {
      switch validationState {
      case .success:
        Image(systemName: "checkmark.circle.fill")
          .foregroundColor(.green)
          .transition(.scale.combined(with: .opacity))
      case .error:
        Image(systemName: "xmark.circle.fill")
          .foregroundColor(.red)
          .transition(.scale.combined(with: .opacity))
      default:
        EmptyView()
      }
    }
    .font(.system(.body))
  }
  
  private func triggerShake() {
    shouldShake = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      shouldShake = false
    }
  }
}

// MARK: - Shake Effect

struct ShakeEffect: GeometryEffect {
  var shakes: CGFloat
  
  var animatableData: CGFloat {
    get { shakes }
    set { shakes = newValue }
  }
  
  func effectValue(size: CGSize) -> ProjectionTransform {
    let translation = sin(shakes * .pi * 2) * 5
    return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
  }
}

// MARK: - Preview

#if DEBUG
struct StyledTextField_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 20) {
      StyledTextField(
        label: "姓名",
        placeholder: "请输入姓名",
        text: .constant(""),
        isRequired: true,
        validationState: .normal
      )
      
      StyledTextField(
        label: "电话号码",
        placeholder: "13800138000",
        text: .constant("13800138000"),
        isRequired: true,
        validationState: .success
      )
      
      StyledTextField(
        label: "邮编",
        placeholder: "100000",
        text: .constant("abc"),
        isRequired: false,
        validationState: .error("无效的邮编格式")
      )
      
      StyledTextField(
        label: "备注",
        placeholder: "可选备注信息",
        text: .constant(""),
        isRequired: false,
        validationState: .normal,
        multiline: true
      )
    }
    .padding(40)
    .frame(width: 400)
  }
}
#endif
