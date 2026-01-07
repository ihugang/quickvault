//
//  CardAttachment+CoreDataProperties.swift
//  QuickVault
//

import CoreData
import Foundation

extension CardAttachment {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<CardAttachment> {
    return NSFetchRequest<CardAttachment>(entityName: "CardAttachment")
  }

  @NSManaged public var id: UUID
  @NSManaged public var fileName: String
  @NSManaged public var fileType: String
  @NSManaged public var fileSize: Int64
  @NSManaged public var encryptedData: Data
  @NSManaged public var thumbnailData: Data?
  @NSManaged public var createdAt: Date
  @NSManaged public var card: Card?
}

extension CardAttachment: Identifiable {

}
