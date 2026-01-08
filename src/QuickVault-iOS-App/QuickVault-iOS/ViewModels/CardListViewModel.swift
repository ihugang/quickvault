import Combine
import Foundation
import QuickVaultCore

/// Card group filter / 卡片分组过滤
enum CardGroup: String, CaseIterable {
    case all = "全部 / All"
    case personal = "个人 / Personal"
    case company = "公司 / Company"
    
    var rawGroupValue: String? {
        switch self {
        case .all: return nil
        case .personal: return "Personal"
        case .company: return "Company"
        }
    }
}

/// Card list view model / 卡片列表视图模型
@MainActor
class CardListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var cards: [CardDTO] = []
    @Published var filteredCards: [CardDTO] = []
    @Published var selectedGroup: CardGroup = .all
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let cardService: CardService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(cardService: CardService) {
        self.cardService = cardService
        setupBindings()
    }
    
    private func setupBindings() {
        // React to search query changes
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                Task {
                    await self?.performSearch(query: query)
                }
            }
            .store(in: &cancellables)
        
        // React to group filter changes
        $selectedGroup
            .sink { [weak self] _ in
                self?.applyFilters()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadCards() async {
        isLoading = true
        errorMessage = nil
        
        do {
            cards = try await cardService.fetchAllCards()
            applyFilters()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Search
    
    private func performSearch(query: String) async {
        guard !query.isEmpty else {
            applyFilters()
            return
        }
        
        isLoading = true
        
        do {
            let searchResults = try await cardService.searchCards(query: query)
            cards = searchResults
            applyFilters()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Filtering
    
    func filterByGroup(_ group: CardGroup) {
        selectedGroup = group
    }
    
    private func applyFilters() {
        var result = cards
        
        // Apply group filter
        if let groupValue = selectedGroup.rawGroupValue {
            result = result.filter { $0.group == groupValue }
        }
        
        // Sort: pinned first, then by modification date
        result = sortCards(result)
        
        filteredCards = result
    }
    
    private func sortCards(_ cards: [CardDTO]) -> [CardDTO] {
        cards.sorted { card1, card2 in
            // Pinned cards first
            if card1.isPinned != card2.isPinned {
                return card1.isPinned
            }
            // Then by modification date (most recent first)
            return card1.updatedAt > card2.updatedAt
        }
    }
    
    // MARK: - Card Operations
    
    func deleteCard(_ id: UUID) async {
        do {
            try await cardService.deleteCard(id: id)
            cards.removeAll { $0.id == id }
            applyFilters()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func togglePin(_ id: UUID) async {
        do {
            let updatedCard = try await cardService.togglePin(id: id)
            if let index = cards.firstIndex(where: { $0.id == id }) {
                cards[index] = updatedCard
            }
            applyFilters()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Refresh
    
    func refresh() async {
        if searchQuery.isEmpty {
            await loadCards()
        } else {
            await performSearch(query: searchQuery)
        }
    }
    
    // MARK: - Clear Error
    
    func clearError() {
        errorMessage = nil
    }
}
