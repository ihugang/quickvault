import SwiftUI

/// Toast notification view / 提示通知视图
struct ToastView: View {
    let message: String
    var isSuccess: Bool = true
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 12) {
                Image(systemName: isSuccess ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundStyle(isSuccess ? .green : .red)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 5)
            )
            .padding(.horizontal, 20)
            .padding(.bottom, 100)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: message)
    }
}

/// Toast modifier for easy use / Toast 修饰器
struct ToastModifier: ViewModifier {
    @Binding var message: String?
    var isSuccess: Bool = true
    var duration: TimeInterval = 2.0
    
    func body(content: Content) -> some View {
        content
            .overlay {
                if let message = message {
                    ToastView(message: message, isSuccess: isSuccess)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                                withAnimation {
                                    self.message = nil
                                }
                            }
                        }
                }
            }
    }
}

extension View {
    func toast(message: Binding<String?>, isSuccess: Bool = true, duration: TimeInterval = 2.0) -> some View {
        modifier(ToastModifier(message: message, isSuccess: isSuccess, duration: duration))
    }
}

#Preview {
    VStack {
        ToastView(message: "已复制 / Copied", isSuccess: true)
        ToastView(message: "操作失败 / Failed", isSuccess: false)
    }
}
