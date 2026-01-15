//
//  FileContent+CoreDataProperties.swift
//  QuickVault
//

import CoreData
import Foundation

extension FileContent {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<FileContent> {
    return NSFetchRequest<FileContent>(entityName: "FileContent")
  }

  @NSManaged public var id: UUID?
  @NSManaged public var fileName: String?
  @NSManaged public var fileURL: String?
  @NSManaged public var thumbnailData: Data?
  @NSManaged public var fileSize: Int64
  @NSManaged public var mimeType: String?
  @NSManaged public var displayOrder: Int16
  @NSManaged public var createdAt: Date?
  @NSManaged public var item: Item?
}

extension FileContent: Identifiable {

}