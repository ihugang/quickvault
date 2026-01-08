//
//  TagInputView.swift
//  QuickVault
//
//  Created on 2026-01-07.
//  Modern tag input with chip display and easy removal
//

import SwiftUI
import QuickVaultCore

/// Tag chip with remove button
struct TagChip: View {
  let tag: String
  let onRemove: () -> Void
  
  @State private var isHovered = false
  
  var body: some View {
    HStack(spacing: 4) {
      Text(tag)
        .font(.system(.caption, design: .rounded))
        .foregroundColor(.primary)
      
      Button(action: onRemove) {
        Image(systemName: "xmark.circle.fill")
          .font(.system(.caption))
          .foregroundColor(isHovered ? .red : .secondary)
      }
      .buttonStyle(.plain)
      .onHover { hovering in
        isHovered = hovering
      }
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(
      RoundedRectangle(cornerRadius: 6)
        .fill(Color.accentColor.opacity(0.15))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 6)
        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
    )
  }
}

/// Enhanced tag input view with visual chips
struct TagInputView: View {
  @Binding var tagsInput: String
  
  @State private var isFocused = false
  @FocusState private var textFieldFocused: Bool
  
  var tags: [String] {
    parseTags(from: tagsInput)
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Label
      HStack(spacing: 4) {
        Text("标签")
          .font(.system(.body, design: .default))
          .fontWeight(.medium)
          .foregroundColor(.primary)
        
        Text("可选")
          .font(.caption)
          .foregroundColor(.secondary)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(Color.secondary.opacity(0.1))
          .cornerRadius(4)
        
        Spacer()
        
        // Hint
        Text("用逗号分隔")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      
      // Tag chips display
      if !tags.isEmpty {
        FlowLayout(spacing: 6) {
          ForEach(tags, id: \.self) { tag in
            TagChip(tag: tag) {
              removeTag(tag)
            }
            .transition(.scale.combined(with: .opacity))
          }
        }
        .animation(.spring(response: 0.3), value: tags)
        .padding(.bottom, 4)
      }
      
      // Input field
      TextField("工作, 重要, 个人...", text: $tagsInput)
        .textFieldStyle(.plain)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(NSColor.textBackgroundColor))
        .cornerRadius(6)
        .overlay(
          RoundedRectangle(cornerRadius: 6)
            .stroke(textFieldFocused ? Color.accentColor : Color.gray.opacity(0.3), lineWidth: textFieldFocused ? 2 : 1)
        )
        .focused($textFieldFocused)
      
      // Quick add suggestions (placeholder for future)
      if textFieldFocused && tagsInput.isEmpty {
        HStack(spacing: 8) {
          Text("常用:")
            .font(.caption)
            .foregroundColor(.secondary)
          
          ForEach(["工作", "个人", "重要"], id: \.self) { suggestion in
            Button(suggestion) {
              addTag(suggestion)
            }
            .buttonStyle(.plain)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(4)
          }
        }
        .transition(.opacity)
      }
    }
  }
  
  private func parseTags(from input: String) -> [String] {
    input
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
  }
  
  private func removeTag(_ tag: String) {
    let currentTags = parseTags(from: tagsInput)
    let updatedTags = currentTags.filter { $0 != tag }
    tagsInput = updatedTags.joined(separator: ", ")
  }
  
  private func addTag(_ tag: String) {
    let currentTags = parseTags(from: tagsInput)
    if !currentTags.contains(tag) {
      if tagsInput.isEmpty {
        tagsInput = tag
      } else {
        tagsInput += ", " + tag
      }
    }
  }
}

// MARK: - Flow Layout

/// Simple flow layout for wrapping tag chips
struct FlowLayout: Layout {
  var spacing: CGFloat = 8
  
  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let result = FlowResult(
      in: proposal.replacingUnspecifiedDimensions().width,
      subviews: subviews,
      spacing: spacing
    )
    return result.size
  }
  
  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let result = FlowResult(
      in: bounds.width,
      subviews: subviews,
      spacing: spacing
    )
    for (index, subview) in subviews.enumerated() {
      subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
    }
  }
  
  struct FlowResult {
    var size: CGSize = .zero
    var positions: [CGPoint] = []
    
    init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
      var currentX: CGFloat = 0
      var currentY: CGFloat = 0
      var lineHeight: CGFloat = 0
      
      for subview in subviews {
        let size = subview.sizeThatFits(.unspecified)
        
        if currentX + size.width > maxWidth && currentX > 0 {
          // Move to next line
          currentX = 0
          currentY += lineHeight + spacing
          lineHeight = 0
        }
        
        positions.append(CGPoint(x: currentX, y: currentY))
        lineHeight = max(lineHeight, size.height)
        currentX += size.width + spacing
      }
      
      self.size = CGSize(
        width: maxWidth,
        height: currentY + lineHeight
      )
    }
  }
}

// MARK: - Preview

#if DEBUG
struct TagInputView_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 30) {
      TagInputView(tagsInput: .constant(""))
      
      TagInputView(tagsInput: .constant("工作, 重要"))
      
      TagInputView(tagsInput: .constant("个人, 家庭, 紧急, 待办, 需要跟进"))
    }
    .padding(40)
    .frame(width: 500)
  }
}
#endif
