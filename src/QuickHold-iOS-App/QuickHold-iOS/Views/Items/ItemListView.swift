//
//  ItemListView.swift
//  QuickHold
//
//  优雅的主列表视图
//

import SwiftUI
import QuickHoldCore

// MARK: - Color Palette
private enum ListPalette {
    // Primary - 深蓝色（安全与信任）
    static let primary = Color(red: 0.20, green: 0.40, blue: 0.70)       // #3366B3
    static let secondary = Color(red: 0.15, green: 0.65, blue: 0.60)     // #26A699 青绿色
    static let accent = Color(red: 0.95, green: 0.70, blue: 0.20)        // #F2B333 金色

    // Neutral - 自适应颜色（支持 Dark Mode）
    static let canvasTop = Color(.systemGroupedBackground)
    static let canvasBottom = Color(.systemGroupedBackground)
    static let card = Color(.secondarySystemGroupedBackground)
    static let border = Color(.separator)
}

struct ItemListView: View {
    @StateObject private var viewModel: ItemListViewModel
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @ObservedObject private var syncMonitor = CloudSyncMonitor.shared
    @State private var showingCreateSheet = false
    @State private var selectedItemType: ItemType?
    @State private var searchText = ""
    @Environment(\.scenePhase) private var scenePhase

    init(itemService: ItemService) {
        _viewModel = StateObject(wrappedValue: ItemListViewModel(itemService: itemService))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景渐变
                backgroundGradient

                VStack(spacing: 0) {
                    // 搜索栏
                    searchBar

                    // Tag 过滤
                    if !viewModel.allTags.isEmpty {
                        tagFilterBar
                    }

                    // 新内容横幅
                    if syncMonitor.newItemCount > 0 {
                        newItemsBanner
                    }

                    // 内容区域
                    if viewModel.isLoading {
                        loadingView
                    } else if viewModel.filteredItems.isEmpty {
                        emptyStateView
                    } else {
                        itemsScrollView
                    }
                }
            }
            .navigationTitle(localizationManager.localizedString("items.title"))
            .navigationBarTitleDisplayMode(.large)
            .environment(\.layoutDirection, localizationManager.layoutDirection)
            .tint(ListPalette.primary)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    syncStatusIcon
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // 排序按钮
                    sortButton
                    
                    // 创建按钮
                    createButton
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateItemSheet(
                    itemService: viewModel.itemService,
                    selectedType: $selectedItemType
                ) {
                    Task { await viewModel.loadItems() }
                }
            }
            .task {
                await viewModel.loadItems()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    // 从后台返回前台时自动刷新
                    Task {
                        await viewModel.loadItems()
                    }
                }
            }
        }
    }

    // MARK: - Sync Status Icon

    private var syncStatusIcon: some View {
        Button {
            syncMonitor.manualSync()
        } label: {
            Group {
                switch syncMonitor.syncStatus {
                case .synced:
                    Image(systemName: "icloud.and.arrow.down")
                        .foregroundStyle(.green)
                case .syncing:
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Image(systemName: "icloud")
                    }
                    .foregroundStyle(.blue)
                case .notSynced:
                    Image(systemName: "icloud.slash")
                        .foregroundStyle(.orange)
                case .error:
                    Image(systemName: "exclamationmark.icloud")
                        .foregroundStyle(.red)
                }
            }
            .font(.body)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                ListPalette.canvasTop,
                ListPalette.canvasBottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(localizationManager.localizedString("items.search.placeholder"), text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.systemGray6))
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .onChange(of: searchText) { newValue in
            viewModel.searchQuery = newValue
        }
    }

    // MARK: - New Items Banner

    private var newItemsBanner: some View {
        Button {
            // 点击后标记为已读（无动画，直接刷新）
            syncMonitor.markNewItemsAsRead()
        } label: {
            HStack(spacing: 10) {
                // 图标（减小）
                Image(systemName: "arrow.down.circle.fill")
                    .font(.body)
                    .foregroundStyle(.blue)

                // 文字（简化）
                Text("有 \(syncMonitor.newItemCount) 个新项目")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.primary)

                Spacer()

                // 关闭按钮（减小）
                Image(systemName: "xmark")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)  // 减小高度
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.blue.opacity(0.06))  // 更浅的背景
            )
            .padding(.horizontal, 20)
            .padding(.vertical, 4)
        }
        .pillTapFeedback()
        .transition(AnimationConstants.opacityTransition)
    }

    // MARK: - Tag Filter Bar
        
    private var tagFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.allTags, id: \.self) { tag in
                    Button {
                        if viewModel.selectedTags.contains(tag) {
                            viewModel.selectedTags.remove(tag)
                        } else {
                            viewModel.selectedTags.insert(tag)
                        }
                    } label: {
                        Text(tag)
                            .font(.subheadline.weight(.medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedTags.contains(tag) ? ListPalette.primary : Color(.systemGray6))
                            )
                            .foregroundStyle(viewModel.selectedTags.contains(tag) ? .white : .primary)
                    }
                    .pillTapFeedback()
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 4)
    }
        
    // MARK: - Toolbar Buttons
        
    /// 排序按钮（导航栏）
    private var sortButton: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button {
                    viewModel.sortOption = option
                } label: {
                    HStack {
                        Text(option.localizedString)
                        if viewModel.sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .font(.body)
        }
    }
    
    // MARK: - Create Button
    
    private var createButton: some View {
        Menu {
            Button {
                selectedItemType = .text
                showingCreateSheet = true
            } label: {
                Label(localizationManager.localizedString("items.type.text"), systemImage: "doc.text")
            }
            
            Button {
                selectedItemType = .image
                showingCreateSheet = true
            } label: {
                Label(localizationManager.localizedString("items.type.image"), systemImage: "photo")
            }
            
            Button {
                selectedItemType = .file
                showingCreateSheet = true
            } label: {
                Label(localizationManager.localizedString("items.type.file"), systemImage: "folder.fill")
            }
        } label: {
            Image(systemName: "plus")
                .font(.body)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text(localizationManager.localizedString("items.loading"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: searchText.isEmpty ? "tray" : "magnifyingglass")
                .font(.system(size: 64))
                .foregroundStyle(.tertiary)
            
            VStack(spacing: 8) {
                Text(localizationManager.localizedString(searchText.isEmpty ? "items.empty" : "items.empty.search"))
                    .font(.title3.weight(.semibold))
                
                Text(localizationManager.localizedString(searchText.isEmpty ? "items.empty.subtitle" : "items.empty.search.subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if searchText.isEmpty {
                Button {
                    selectedItemType = .text
                    showingCreateSheet = true
                } label: {
                    Label(localizationManager.localizedString("items.create.text"), systemImage: "doc.text")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(ListPalette.primary)
                        )
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
    
    // MARK: - Items Scroll View

    private var itemsScrollView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // 置顶卡片
                if !viewModel.pinnedItems.isEmpty {
                    pinnedSection
                }

                // 普通卡片
                if !viewModel.unpinnedItems.isEmpty {
                    regularSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .refreshable {
            await viewModel.loadItems()
        }
    }
    
    // MARK: - Pinned Section
    
    private var pinnedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pin.fill")
                    .font(.caption)
                Text(localizationManager.localizedString("items.pinned"))
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
            
            ForEach(viewModel.pinnedItems) { item in
                NavigationLink {
                    ItemDetailView(item: item, itemService: viewModel.itemService) {
                        Task { await viewModel.loadItems() }
                    }
                } label: {
                    ItemCard(item: item, isNew: syncMonitor.isNewItem(item.id))
                }
                .cardTapFeedback()
            }
        }
    }
    
    // MARK: - Regular Section
    
    private var regularSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.pinnedItems.isEmpty {
                HStack {
                    Image(systemName: "square.stack")
                        .font(.caption)
                    Text(localizationManager.localizedString("items.all"))
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.secondary)
                .padding(.leading, 4)
            }
            
            ForEach(viewModel.unpinnedItems) { item in
                NavigationLink {
                    ItemDetailView(item: item, itemService: viewModel.itemService) {
                        Task { await viewModel.loadItems() }
                    }
                } label: {
                    ItemCard(item: item, isNew: syncMonitor.isNewItem(item.id))
                }
                .cardTapFeedback()
            }
        }
    }
}

// MARK: - Item Card Component

struct ItemCard: View {
    let item: ItemDTO
    var isNew: Bool = false
    @ObservedObject private var localizationManager = LocalizationManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 顶部行：图标 + 标题 + 时间
            HStack(alignment: .top, spacing: 12) {
                // 类型图标
                itemTypeIcon
                    
                // 标题（允许2行）
                Text(item.title)
                    .font(.body.weight(.medium))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                // 右侧：时间（更突出）
                VStack(alignment: .trailing, spacing: 2) {
                    Text(localizationManager.formatRelativeDate(item.updatedAt))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        
                    // 置顶标记
                    if item.isPinned {
                        HStack(spacing: 3) {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                            Text("置顶")
                                .font(.caption2)
                        }
                        .foregroundStyle(.orange)
                    }
                }
                .fixedSize(horizontal: true, vertical: false)
            }
                
            // 内容预览（浅色，最套2行）
            contentPreview
                
            // 底部行：左侧标签 + 右侧数量和状态
            HStack(alignment: .center, spacing: 8) {
                // 左侧：标签
                if !item.tags.isEmpty {
                    compactTagsView
                } else {
                    // 占位空间，保持布局一致
                    Text(" ")
                        .font(.caption2)
                }
                    
                Spacer()
                    
                // 右侧：数量 + 状态
                HStack(spacing: 8) {
                    // 图片/文件数量指示
                    if item.type == .image, let images = item.images, !images.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "photo")
                            Text("\(images.count)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6))
                        )
                    } else if item.type == .file, let files = item.files, !files.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "doc")
                            Text("\(files.count)")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6))
                        )
                    }
                        
                    // 新项目标签
                    if isNew {
                        Text("新")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.blue)
                            )
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(ListPalette.card)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }
    
    private var itemTypeIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(item.type == .text ? Color.blue.opacity(0.1) : ListPalette.primary.opacity(0.12))
                .frame(width: 20, height: 20)
            
            Image(systemName: item.type.icon)
                .font(.caption2)
                .foregroundStyle(item.type == .text ? .blue : ListPalette.primary)
        }
    }
    
    @ViewBuilder
    private var contentPreview: some View {
        if item.type == .text, let content = item.textContent, !content.isEmpty {
            Text(content)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)  // 减少从 3 → 2 行
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
        }
    }
    
    private func formatTotalFileSize(_ files: [FileDTO]) -> String {
        let totalBytes = files.reduce(0) { $0 + $1.fileSize }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalBytes)
    }
    
    // MARK: - Compact Tags View
    
    /// 紧凑的标签显示（最多2个 + 数量）
    private var compactTagsView: some View {
        HStack(spacing: 4) {
            ForEach(item.tags.prefix(2), id: \.self) { tag in
                Text(tag)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color(.systemGray6))
                    )
            }
            
            if item.tags.count > 2 {
                Text("+\(item.tags.count - 2)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

#Preview {
    ItemListView(itemService: ItemServiceImpl(
        persistenceController: PersistenceController.preview
    ))
}
