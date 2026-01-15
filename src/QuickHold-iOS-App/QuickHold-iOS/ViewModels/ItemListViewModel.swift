//
//  ItemListViewModel.swift
//  QuickHold
//

import Foundation
import QuickHoldCore
import Combine

@MainActor
class ItemListViewModel: ObservableObject {
    @Published var items: [ItemDTO] = []
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    
    let itemService: ItemService
    
    var filteredItems: [ItemDTO] {
        if searchQuery.isEmpty {
            return items
        } else {
            return items.filter { item in
                item.title.localizedCaseInsensitiveContains(searchQuery) ||
                item.tags.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
            }
        }
    }
    
    var pinnedItems: [ItemDTO] {
        filteredItems.filter { $0.isPinned }
    }
    
    var unpinnedItems: [ItemDTO] {
        filteredItems.filter { !$0.isPinned }
    }
    
    init(itemService: ItemService) {
        self.itemService = itemService
    }
    
    func loadItems() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await itemService.fetchAllItems()
        } catch {
            print("Error loading items: \(error)")
        }
    }
}
