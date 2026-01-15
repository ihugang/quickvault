//
//  ItemService+Examples.swift
//  QuickHold
//
//  使用示例 / Usage Examples
//

import Foundation

/*
 
 ## 使用场景示例 / Usage Examples
 
 ### 1. 创建文本卡片
 
 ```swift
 let itemService = ItemServiceImpl(persistenceController: persistenceController)
 
 // 创建一个收货地址卡片
 let addressItem = try await itemService.createTextItem(
     title: "家庭收货地址",
     content: """
     收件人：张三
     电话：13800138000
     地址：北京市朝阳区xxx路xxx号
     邮编：100000
     """,
     tags: ["地址", "家庭"]
 )
 ```
 
 ### 2. 创建图片卡片
 
 ```swift
 // 创建一个身份证照片卡片
 let frontImageData = ImageData(data: idCardFrontData, fileName: "身份证正面.jpg")
 let backImageData = ImageData(data: idCardBackData, fileName: "身份证反面.jpg")
 
 let idCardItem = try await itemService.createImageItem(
     title: "身份证照片",
     images: [frontImageData, backImageData],
     tags: ["证件", "身份证"]
 )
 ```
 
 ### 3. 搜索卡片
 
 ```swift
 // 搜索所有包含"地址"的卡片
 let results = try await itemService.searchItems(query: "地址")
 
 // 获取所有卡片
 let allItems = try await itemService.fetchAllItems()
 ```
 
 ### 4. 分享文本内容
 
 ```swift
 // 获取文本内容用于分享
 let text = try await itemService.getShareableText(id: addressItem.id)
 
 // 复制到剪贴板
 UIPasteboard.general.string = text
 
 // 或使用系统分享
 let activityVC = UIActivityViewController(
     activityItems: [text],
     applicationActivities: nil
 )
 present(activityVC, animated: true)
 ```
 
 ### 5. 分享图片（无水印）
 
 ```swift
 // 获取原图
 let images = try await itemService.getShareableImages(
     id: idCardItem.id,
     withWatermark: false,
     watermarkText: nil
 )
 
 // 转换为 UIImage
 let uiImages = images.compactMap { UIImage(data: $0) }
 
 // 系统分享
 let activityVC = UIActivityViewController(
     activityItems: uiImages,
     applicationActivities: nil
 )
 present(activityVC, animated: true)
 ```
 
 ### 6. 分享图片（加水印）
 
 ```swift
 // 获取带水印的图片
 let watermarkedImages = try await itemService.getShareableImages(
     id: idCardItem.id,
     withWatermark: true,
     watermarkText: "仅供XX使用"
 )
 
 // 分享或保存
 let uiImages = watermarkedImages.compactMap { UIImage(data: $0) }
 // ... 使用 UIActivityViewController 分享
 ```
 
 ### 7. 更新卡片
 
 ```swift
 // 更新文本内容
 let updated = try await itemService.updateTextItem(
     id: addressItem.id,
     title: "公司收货地址",
     content: "...",
     tags: ["地址", "公司"]
 )
 
 // 只更新标签
 let _ = try await itemService.updateImageItem(
     id: idCardItem.id,
     title: nil,
     tags: ["证件", "身份证", "重要"]
 )
 ```
 
 ### 8. 图片卡片管理
 
 ```swift
 // 添加更多图片到现有卡片
 let newImage = ImageData(data: photoData, fileName: "补充照片.jpg")
 try await itemService.addImages(to: idCardItem.id, images: [newImage])
 
 // 删除某张图片
 if let imageToRemove = idCardItem.images?.first {
     try await itemService.removeImage(id: imageToRemove.id)
 }
 ```
 
 ### 9. 置顶重要卡片
 
 ```swift
 // 切换置顶状态
 let toggled = try await itemService.togglePin(id: addressItem.id)
 print("Is pinned: \(toggled.isPinned)")
 ```
 
 ### 10. 删除卡片
 
 ```swift
 // 删除不需要的卡片
 try await itemService.deleteItem(id: oldItem.id)
 ```
 
 ## 完整用户流程示例
 
 ```swift
 class ItemViewModel: ObservableObject {
     @Published var items: [ItemDTO] = []
     @Published var searchQuery: String = ""
     
     private let itemService: ItemService
     
     init(itemService: ItemService) {
         self.itemService = itemService
     }
     
     // 加载所有卡片
     func loadItems() async {
         do {
             if searchQuery.isEmpty {
                 items = try await itemService.fetchAllItems()
             } else {
                 items = try await itemService.searchItems(query: searchQuery)
             }
         } catch {
             print("Error loading items: \(error)")
         }
     }
     
     // 创建文本卡片
     func createTextCard(title: String, content: String, tags: [String]) async {
         do {
             _ = try await itemService.createTextItem(
                 title: title,
                 content: content,
                 tags: tags
             )
             await loadItems()
         } catch {
             print("Error creating text item: \(error)")
         }
     }
     
     // 分享文本
     func shareText(itemId: UUID) async -> String? {
         do {
             return try await itemService.getShareableText(id: itemId)
         } catch {
             print("Error getting shareable text: \(error)")
             return nil
         }
     }
     
     // 分享图片
     func shareImages(itemId: UUID, withWatermark: Bool, watermarkText: String?) async -> [Data]? {
         do {
             return try await itemService.getShareableImages(
                 id: itemId,
                 withWatermark: withWatermark,
                 watermarkText: watermarkText
             )
         } catch {
             print("Error getting shareable images: \(error)")
             return nil
         }
     }
 }
 ```
 
 */
