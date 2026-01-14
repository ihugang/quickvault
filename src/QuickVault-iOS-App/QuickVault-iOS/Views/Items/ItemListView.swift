//
//  ItemListView.swift
//  QuickVault
//
//  优雅的主列表视图
//

import SwiftUI
import QuickVaultCore

struct ItemListView: View {
    @StateObject private var viewModel: ItemListViewModel
    @State private var showingCreateSheet = false
    @State private var selectedItemType: ItemType?
    @State private var searchText = ""
    
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
            .navigationTitle("随取 QuickVault")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
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
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.systemBackground).opacity(0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                
                TextField("搜索标题或标签...", text: $searchText)
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
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.systemGray6))
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .onChange(of: searchText) { _, newValue in
            viewModel.searchQuery = newValue
        }
    }
    
    // MARK: - Create Button
    
    private var createButton: some View {
        Menu {
            Button {
                selectedItemType = .text
                showingCreateSheet = true
            } label: {
                Label("文本卡片", systemImage: "doc.text")
            }
            
            Button {
                selectedItemType = .image
                showingCreateSheet = true
            } label: {
                Label("图片卡片", systemImage: "photo")
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("加载中...")
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
                Text(searchText.isEmpty ? "还没有卡片" : "未找到结果")
                    .font(.title3.weight(.semibold))
                
                Text(searchText.isEmpty ? "点击右上角 + 创建第一张卡片" : "试试其他搜索关键词")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if searchText.isEmpty {
                Button {
                    selectedItemType = .text
                    showingCreateSheet = true
                } label: {
                    Label("创建文本卡片", systemImage: "doc.text")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.accentColor)
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
    }
    
    // MARK: - Pinned Section
    
    private var pinnedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "pin.fill")
                    .font(.caption)
                Text("置顶")
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
                    ItemCard(item: item)
                }
                .buttonStyle(.plain)
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
                    Text("全部")
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
                    ItemCard(item: item)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Item Card Component

struct ItemCard: View {
    let item: ItemDTO
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 头部
            HStack(alignment: .top) {
                // 类型图标
                itemTypeIcon
                
                VStack(alignment: .leading, spacing: 6) {
                    // 标题
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    // 时间
                    Text(item.updatedAt.formatted(.relative(presentation: .named)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // 置顶标记
                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            // 内容预览
            contentPreview
            
            // 标签
            if !item.tags.isEmpty {
                tagsView
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
        )
    }
    
    private var itemTypeIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(item.type == .text ? Color.blue.opacity(0.1) : Color.purple.opacity(0.1))
                .frame(width: 44, height: 44)
            
            Image(systemName: item.type.icon)
                .font(.title3)
                .foregroundStyle(item.type == .text ? .blue : .purple)
        }
    }
    
    @ViewBuilder
    private var contentPreview: some View {
        if item.type == .text, let content = item.textContent {
            Text(content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if item.type == .image, let images = item.images, !images.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(images.prefix(4)) { image in
                        if let thumbnailData = image.thumbnailData,
                           let uiImage = UIImage(data: thumbnailData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                    
                    if images.count > 4 {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color(.systemGray5))
                                .frame(width: 80, height: 80)
                            
                            Text("+\(images.count - 4)")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
    
    private var tagsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(item.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray6))
                        )
                }
            }
        }
    }
}

#Preview {
    ItemListView(itemService: ItemServiceImpl(
        persistenceController: PersistenceController.preview
    ))
}
