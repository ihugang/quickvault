//
//  ItemListViewModel.swift
//  QuickHold
//

import Foundation
import QuickHoldCore
import Combine

enum SortOption: String, CaseIterable {
    case createdTime = "创建时间"
    case type = "类型"
    case updatedTime = "更新时间"
}

@MainActor
class ItemListViewModel: ObservableObject {
    @Published var items: [ItemDTO] = []
    @Published var searchQuery: String = ""
    @Published var selectedTags: Set<String> = []
    @Published var sortOption: SortOption = .createdTime
    @Published var isLoading: Bool = false

    let itemService: ItemService

    var allTags: [String] {
        let tagSet = Set(items.flatMap { $0.tags })
        return Array(tagSet).sorted()
    }

    var filteredItems: [ItemDTO] {
        var result = items

        // 按搜索关键词过滤
        if !searchQuery.isEmpty {
            result = result.filter { item in
                item.title.localizedCaseInsensitiveContains(searchQuery) ||
                item.tags.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
            }
        }

        // 按选中的 tags 过滤
        if !selectedTags.isEmpty {
            result = result.filter { item in
                !Set(item.tags).isDisjoint(with: selectedTags)
            }
        }

        // 排序
        switch sortOption {
        case .createdTime:
            result.sort { $0.createdAt > $1.createdAt }
        case .type:
            result.sort { $0.type.rawValue < $1.type.rawValue }
        case .updatedTime:
            result.sort { $0.updatedAt > $1.updatedAt }
        }

        return result
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
