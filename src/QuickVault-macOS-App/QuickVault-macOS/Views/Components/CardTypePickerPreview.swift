//
//  CardTypePickerPreview.swift
//  QuickVault Preview
//
//  Preview for the compact horizontal card type picker
//

import SwiftUI
import QuickVaultCore

struct CardTypePickerPreview: View {
  @State private var selectedType: CardType = .general
  
  var body: some View {
    VStack(spacing: 30) {
      Text("卡片类型选择器 - 水平布局")
        .font(.title2)
        .fontWeight(.bold)
      
      CardTypePickerView(
        selectedType: $selectedType,
        isDisabled: false
      )
      
      Text("当前选择: \(selectedType.displayName)")
        .font(.caption)
        .foregroundColor(.secondary)
      
      Divider()
      
      Text("编辑模式（禁用）")
        .font(.headline)
      
      CardTypePickerView(
        selectedType: $selectedType,
        isDisabled: true
      )
    }
    .padding(40)
    .frame(width: 700)
  }
}

#if DEBUG
struct CardTypePickerPreview_Previews: PreviewProvider {
  static var previews: some View {
    CardTypePickerPreview()
  }
}
#endif
