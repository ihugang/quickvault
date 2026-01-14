//
//  Item+CoreDataProperties.swift
//  QuickVault
//

import CoreData
import Foundation

extension Item {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<Item> {
    return NSFetchRequest<Item>(entityName: "Item")
  }

  @NSManaged public var id: UUID
  @NSManaged public var title: String
  @NSManaged public var type: String
  @NSManaged public var tagsJSON: String?
  @NSManaged public var isPinned: Bool
  @NSManaged public var createdAt: Date
  @NSManaged public var updatedAt: Date
  @NSManaged public var textContent: TextContent?
  @NSManaged public var images: NSSet?
}

// MARK: Generated accessors for images
extension Item {
  @objc(addImagesObject:)
  @NSManaged public func addToImages(_ value: ImageContent)

  @objc(removeImagesObject:)
  @NSManaged public func removeFromImages(_ value: ImageContent)

  @objc(addImages:)
  @NSManaged public func addToImages(_ values: NSSet)

  @objc(removeImages:)
  @NSManaged public func removeFromImages(_ values: NSSet)
}

extension Item: Identifiable {

}
