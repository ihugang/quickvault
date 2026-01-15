//
//  ImageContent+CoreDataProperties.swift
//  QuickHold
//

import CoreData
import Foundation

extension ImageContent {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<ImageContent> {
    return NSFetchRequest<ImageContent>(entityName: "ImageContent")
  }

  @NSManaged public var id: UUID?
  @NSManaged public var fileName: String?
  @NSManaged public var encryptedData: Data?
  @NSManaged public var thumbnailData: Data?
  @NSManaged public var fileSize: Int64
  @NSManaged public var displayOrder: Int16
  @NSManaged public var createdAt: Date?
  @NSManaged public var item: Item?
}

extension ImageContent: Identifiable {

}
