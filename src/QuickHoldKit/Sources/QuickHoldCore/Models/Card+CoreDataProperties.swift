//
//  Card+CoreDataProperties.swift
//  QuickHold
//

import CoreData
import Foundation

extension Card {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<Card> {
    return NSFetchRequest<Card>(entityName: "Card")
  }

  @NSManaged public var id: UUID
  @NSManaged public var title: String
  @NSManaged public var type: String
  @NSManaged public var group: String
  @NSManaged public var tagsJSON: String?
  @NSManaged public var isPinned: Bool
  @NSManaged public var createdAt: Date
  @NSManaged public var updatedAt: Date
  @NSManaged public var fields: NSSet?
  @NSManaged public var attachments: NSSet?
}

// MARK: Generated accessors for fields
extension Card {
  @objc(addFieldsObject:)
  @NSManaged public func addToFields(_ value: CardField)

  @objc(removeFieldsObject:)
  @NSManaged public func removeFromFields(_ value: CardField)

  @objc(addFields:)
  @NSManaged public func addToFields(_ values: NSSet)

  @objc(removeFields:)
  @NSManaged public func removeFromFields(_ values: NSSet)
}

// MARK: Generated accessors for attachments
extension Card {
  @objc(addAttachmentsObject:)
  @NSManaged public func addToAttachments(_ value: CardAttachment)

  @objc(removeAttachmentsObject:)
  @NSManaged public func removeFromAttachments(_ value: CardAttachment)

  @objc(addAttachments:)
  @NSManaged public func addToAttachments(_ values: NSSet)

  @objc(removeAttachments:)
  @NSManaged public func removeFromAttachments(_ values: NSSet)
}

extension Card: Identifiable {

}
