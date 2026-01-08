//
//  SetupView.swift
//  QuickVault
//
//  Initial setup view for creating master password
//

import SwiftUI
import QuickVaultCore

struct SetupView: View {
  @State private var password: String = ""
  @State private var confirmPassword: String = ""
  @State private var errorMessage: String?
  @State private var isProcessing = false
  
  let authService: AuthenticationService
  let onComplete: () -> Void
  
  var body: some View {
    VStack(spacing: 30) {
      // Header
      VStack(spacing: 12) {
        ZStack {
          Circle()
            .fill(
              LinearGradient(
                colors: [Color.blue, Color.purple],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 80, height: 80)
          
          Image(systemName: "lock.shield.fill")
            .font(.system(size: 40))
            .foregroundColor(.white)
        }
        
        Text("欢迎使用 QuickVault")
          .font(.title)
          .fontWeight(.bold)
        
        Text("首次使用，请设置主密码")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      .padding(.top, 40)
      
      // Password fields
      VStack(alignment: .leading, spacing: 20) {
        VStack(alignment: .leading, spacing: 8) {
          Text("主密码")
            .font(.headline)
          SecureField("至少8个字符", text: $password)
            .textFieldStyle(.plain)
            .padding(12)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        
        VStack(alignment: .leading, spacing: 8) {
          Text("确认密码")
            .font(.headline)
          SecureField("再次输入密码", text: $confirmPassword)
            .textFieldStyle(.plain)
            .padding(12)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
      }
      .padding(.horizontal, 40)
      
      // Error message
      if let errorMessage = errorMessage {
        HStack(spacing: 8) {
          Image(systemName: "exclamationmark.circle.fill")
            .foregroundColor(.red)
          Text(errorMessage)
            .font(.caption)
            .foregroundColor(.red)
        }
        .transition(.opacity)
      }
      
      // Create button
      Button(action: createPassword) {
        HStack {
          if isProcessing {
            ProgressView()
              .scaleEffect(0.8)
              .frame(width: 16, height: 16)
          } else {
            Image(systemName: "checkmark.circle.fill")
          }
          Text("创建密码")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
      }
      .buttonStyle(.plain)
      .background(
        LinearGradient(
          colors: [Color.blue, Color.purple],
          startPoint: .leading,
          endPoint: .trailing
        )
      )
      .foregroundColor(.white)
      .cornerRadius(10)
      .padding(.horizontal, 40)
      .disabled(isProcessing || password.isEmpty || confirmPassword.isEmpty)
      
      Spacer()
      
      // Info
      VStack(spacing: 8) {
        HStack(spacing: 6) {
          Image(systemName: "info.circle")
            .font(.caption)
          Text("主密码用于加密您的所有数据")
        }
        HStack(spacing: 6) {
          Image(systemName: "key.fill")
            .font(.caption)
          Text("请妥善保管，遗失无法找回")
        }
      }
      .font(.caption)
      .foregroundColor(.secondary)
      .padding(.bottom, 20)
    }
    .frame(width: 450, height: 550)
    .background(
      ZStack {
        Color(NSColor.windowBackgroundColor)
        
        LinearGradient(
          colors: [Color.blue.opacity(0.08), Color.purple.opacity(0.08)],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
    )
  }
  
  private func createPassword() {
    errorMessage = nil
    
    guard password.count >= 8 else {
      errorMessage = "密码至少需要8个字符"
      return
    }
    
    guard password == confirmPassword else {
      errorMessage = "两次输入的密码不一致"
      return
    }
    
    isProcessing = true
    Task {
      do {
        try await authService.setupMasterPassword(password)
        await MainActor.run {
          isProcessing = false
          onComplete()
        }
      } catch {
        await MainActor.run {
          isProcessing = false
          errorMessage = error.localizedDescription
        }
      }
    }
  }
}

#if DEBUG
struct SetupView_Previews: PreviewProvider {
  static var previews: some View {
    SetupView(
      authService: AuthenticationServiceImpl(
        keychainService: KeychainServiceImpl(),
        cryptoService: CryptoServiceImpl()
      ),
      onComplete: {}
    )
  }
}
#endif
