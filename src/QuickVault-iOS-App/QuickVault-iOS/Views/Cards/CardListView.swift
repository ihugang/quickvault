import SwiftUI
import QuickVaultCore

/// Card list view / 卡片列表视图
struct CardListView: View {
    @ObservedObject var viewModel: CardListViewModel
    @State private var showingNewCard = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Group Filter
                GroupFilterView(selectedGroup: $viewModel.selectedGroup)
                
                // Card List
                if viewModel.isLoading && viewModel.filteredCards.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredCards.isEmpty {
                    EmptyStateView(
                        icon: "creditcard",
                        title: "cards.empty".localized,
                        message: "cards.empty.subtitle".localized
                    )
                } else {
                    List {
                        ForEach(viewModel.filteredCards, id: \.id) { card in
                            NavigationLink(value: card) {
                                CardRowView(card: card)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteCard(card.id)
                                    }
                                } label: {
                                    Label("common.delete".localized, systemImage: "trash")
                                }
                                
                                Button {
                                    Task {
                                        await viewModel.togglePin(card.id)
                                    }
                                } label: {
                                    Label(
                                        card.isPinned ? "cards.unpin".localized : "cards.pin".localized,
                                        systemImage: card.isPinned ? "pin.slash" : "pin"
                                    )
                                }
                                .tint(.orange)
                            }
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationTitle("cards.title".localized)
            .navigationDestination(for: CardDTO.self) { card in
                CardDetailView(cardId: card.id)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewCard = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewCard) {
                CardEditorSheet(onSave: {
                    Task {
                        await viewModel.refresh()
                    }
                })
            }
            .task {
                await viewModel.loadCards()
            }
        }
    }
}

/// Group filter view / 分组过滤视图
struct GroupFilterView: View {
    @Binding var selectedGroup: CardGroup
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(CardGroup.allCases, id: \.self) { group in
                    FilterChip(
                        title: group.localizedName,
                        isSelected: selectedGroup == group
                    ) {
                        selectedGroup = group
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }
}

/// Filter chip / 过滤标签
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemBackground))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color(.separator), lineWidth: 1)
                )
        }
    }
}

/// Card row view / 卡片行视图
struct CardRowView: View {
    let card: CardDTO
    
    var body: some View {
        HStack(spacing: 12) {
            // Card Type Icon
            cardTypeIcon
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 44, height: 44)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Card Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(card.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if card.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                
                Text(cardPreview)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Text(groupDisplayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                    
                    if !card.tags.isEmpty {
                        Text(card.tags.first ?? "")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var cardTypeIcon: Image {
        switch card.type {
        case "Address":
            return Image(systemName: "mappin.circle.fill")
        case "Invoice":
            return Image(systemName: "doc.text.fill")
        default:
            return Image(systemName: "text.alignleft")
        }
    }
    
    private var cardPreview: String {
        if let firstField = card.fields.first {
            return firstField.value
        }
        return ""
    }
    
    private var groupDisplayName: String {
        switch card.group {
        case "Personal": return "个人"
        case "Company": return "公司"
        default: return card.group
        }
    }
}

/// Empty state view / 空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
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
    return CardListView(viewModel: CardListViewModel(cardService: cardService))
}
