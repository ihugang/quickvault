import SwiftUI
import QuickVaultCore

/// Main tab view / 主标签视图
struct MainTabView: View {
    @ObservedObject var cardListViewModel: CardListViewModel
    @ObservedObject var settingsViewModel: SettingsViewModel
    
    var body: some View {
        TabView {
            CardListView(viewModel: cardListViewModel)
                .tabItem {
                    Label("卡片 / Cards", systemImage: "creditcard.fill")
                }
            
            SearchView(viewModel: cardListViewModel)
                .tabItem {
                    Label("搜索 / Search", systemImage: "magnifyingglass")
                }
            
            SettingsView(viewModel: settingsViewModel)
                .tabItem {
                    Label("设置 / Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    let persistenceController = PersistenceController.preview
    let cryptoService = CryptoServiceImpl()
    let keychainService = KeychainServiceImpl()
    let cardService = CardServiceImpl(persistenceController: persistenceController, cryptoService: cryptoService)
    let authService = AuthenticationServiceImpl(keychainService: keychainService, cryptoService: cryptoService)
    
    return MainTabView(
        cardListViewModel: CardListViewModel(cardService: cardService),
        settingsViewModel: SettingsViewModel(authService: authService)
    )
}
