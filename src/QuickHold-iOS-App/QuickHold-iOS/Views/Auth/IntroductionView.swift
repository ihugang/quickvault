import SwiftUI

/// Introduction view shown on first app launch / 首次启动介绍视图
/// 展示应用的核心安全特性，让用户了解数据完全本地存储和加密
struct IntroductionView: View {
    @Binding var hasSeenIntroduction: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App Icon
            Image("center-logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding(.bottom, 24)

            // App Name
            Text("app.name".localized)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom, 8)

            Text("app.tagline".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 48)

            // Security Features / 安全特性
            VStack(alignment: .leading, spacing: 24) {
                FeatureRow(
                    icon: "lock.shield.fill",
                    iconColor: .blue,
                    title: "intro.feature.local.title".localized,
                    description: "intro.feature.local.description".localized
                )

                FeatureRow(
                    icon: "key.fill",
                    iconColor: .green,
                    title: "intro.feature.encryption.title".localized,
                    description: "intro.feature.encryption.description".localized
                )

                FeatureRow(
                    icon: "photo.fill",
                    iconColor: .orange,
                    title: "intro.feature.files.title".localized,
                    description: "intro.feature.files.description".localized
                )

                FeatureRow(
                    icon: "hand.raised.fill",
                    iconColor: .red,
                    title: "intro.feature.privacy.title".localized,
                    description: "intro.feature.privacy.description".localized
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            // Continue Button / 继续按钮
            Button(action: {
                withAnimation {
                    hasSeenIntroduction = true
                }
            }) {
                Text("intro.button.continue".localized)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .padding(.top, 60)
    }
}

/// Feature row component / 特性展示行组件
struct FeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 32)

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    IntroductionView(hasSeenIntroduction: .constant(false))
}
