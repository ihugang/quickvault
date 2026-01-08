import SwiftUI
import QuickVaultCore

@main
struct QuickVaultApp: App {
    // TODO: 初始化 PersistenceController / Initialize PersistenceController
    // TODO: 初始化核心服务 / Initialize core services (auth, crypto, card)

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        Text("QuickVault iOS")
            .padding()
    }
}
