import SwiftUI
import QuickVaultCore

/// Search view / 搜索视图
struct SearchView: View {
    @ObservedObject var viewModel: CardListViewModel
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Results
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if searchText.isEmpty {
                    SearchPlaceholderView()
                } else if viewModel.filteredCards.isEmpty {
                    EmptyStateView(
                        icon: "magnifyingglass",
                        title: "search.empty".localized,
                        message: "search.placeholder".localized
                    )
                } else {
                    List {
                        ForEach(viewModel.filteredCards, id: \.id) { card in
                            NavigationLink(value: card) {
                                CardRowView(card: card)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("search.title".localized)
            .searchable(text: $searchText, prompt: "search.placeholder".localized)
            .onChange(of: searchText) { _, newValue in
                viewModel.searchQuery = newValue
            }
            .navigationDestination(for: CardDTO.self) { card in
                CardDetailView(cardId: card.id)
            }
        }
    }
}

/// Search placeholder view / 搜索占位视图
struct SearchPlaceholderView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text("search.title".localized)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("search.placeholder".localized)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    let persistenceController = PersistenceController.preview
    let cryptoService = CryptoServiceImpl()
    let cardService = CardServiceImpl(persistenceController: persistenceController, cryptoService: cryptoService)
    return SearchView(viewModel: CardListViewModel(cardService: cardService))
}
