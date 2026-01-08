//
//  CardTypePickerView.swift
//  QuickVault
//
//  Created on 2026-01-07.
//  Visual card type picker with icons and descriptions
//

import SwiftUI
import QuickVaultCore

/// Card type option with compact horizontal design and themed colors
struct CardTypeOption: View {
  let type: CardType
  let isSelected: Bool
  let onSelect: () -> Void
  
  @State private var isHovered = false
  
  var icon: String {
    switch type {
    case .general: return "note.text"
    case .address: return "location.fill"
    case .invoice: return "doc.text.fill"
    case .businessLicense: return "building.2.fill"
    case .idCard: return "person.text.rectangle"
    }
  }
  
  // Themed gradient colors for each card type
  var gradientColors: [Color] {
    switch type {
    case .general:
      return [Color(red: 0.4, green: 0.6, blue: 1.0), Color(red: 0.6, green: 0.4, blue: 1.0)]  // Blue-Purple
    case .address:
      return [Color(red: 1.0, green: 0.4, blue: 0.5), Color(red: 1.0, green: 0.6, blue: 0.3)]  // Pink-Orange
    case .invoice:
      return [Color(red: 0.2, green: 0.8, blue: 0.6), Color(red: 0.3, green: 0.9, blue: 0.8)]  // Teal-Cyan
    case .businessLicense:
      return [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 1.0, green: 0.8, blue: 0.3)]  // Orange-Yellow
    case .idCard:
      return [Color(red: 0.5, green: 0.4, blue: 1.0), Color(red: 0.7, green: 0.5, blue: 1.0)]  // Purple-Lavender
    }
  }
  
  var themeColor: Color {
    gradientColors[0]
  }
  
  var body: some View {
    Button(action: onSelect) {
      VStack(spacing: 8) {
        // Icon with gradient background circle
        ZStack {
          Circle()
            .fill(
              LinearGradient(
                colors: isSelected ? [.white.opacity(0.3), .white.opacity(0.15)] : gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 40, height: 40)
          
          Image(systemName: icon)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(isSelected ? .white : .white)
        }
        
        // Type name
        Text(type.displayName)
          .font(.system(.caption, design: .rounded))
          .fontWeight(.semibold)
          .foregroundColor(isSelected ? .white : .primary)
          .lineLimit(1)
      }
      .frame(width: 100)
      .padding(.vertical, 12)
      .padding(.horizontal, 8)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(
            isSelected 
              ? LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
              : (isHovered 
                  ? LinearGradient(colors: gradientColors.map { $0.opacity(0.15) }, startPoint: .topLeading, endPoint: .bottomTrailing)
                  : LinearGradient(colors: [Color.clear, Color.clear], startPoint: .top, endPoint: .bottom))
          )
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(
            LinearGradient(
              colors: isSelected ? [.clear] : (isHovered ? gradientColors : [themeColor.opacity(0.3)]),
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: isSelected ? 0 : (isHovered ? 2 : 1)
          )
      )
      .scaleEffect(isHovered && !isSelected ? 1.02 : 1.0)
      .animation(.spring(response: 0.3), value: isHovered)
      .animation(.spring(response: 0.3), value: isSelected)
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      isHovered = hovering
    }
  }
}

/// Visual card type picker - horizontal scrolling layout
struct CardTypePickerView: View {
  @Binding var selectedType: CardType
  let isDisabled: Bool
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Label
      HStack(spacing: 4) {
        Text("卡片类型")
          .font(.system(.body, design: .default))
          .fontWeight(.medium)
          .foregroundColor(.primary)
        
        if isDisabled {
          Text("编辑时不可更改")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(4)
        }
      }
      
      // Horizontal scrolling row of card types
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
          ForEach(CardType.allCases, id: \.self) { type in
          CardTypeOption(
            type: type,
            isSelected: selectedType == type,
            onSelect: {
              if !isDisabled {
                withAnimation(.spring(response: 0.3)) {
                  selectedType = type
                }
              }
            }
          )
          }
        }
        .padding(.vertical, 4)
      }
      .disabled(isDisabled)
      .opacity(isDisabled ? 0.6 : 1.0)
    }
  }
}

// MARK: - Preview

#if DEBUG
struct CardTypePickerView_Previews: PreviewProvider {
  static var previews: some View {
    VStack(spacing: 30) {
      CardTypePickerView(
        selectedType: .constant(.general),
        isDisabled: false
      )
      
      Divider()
      
      CardTypePickerView(
        selectedType: .constant(.address),
        isDisabled: true
      )
    }
    .padding(40)
    .frame(width: 600)
  }
}
#endif
