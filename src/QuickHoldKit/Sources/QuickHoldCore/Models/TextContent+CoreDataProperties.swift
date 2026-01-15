//
//  TextContent+CoreDataProperties.swift
//  QuickHold
//

import CoreData
import Foundation

extension TextContent {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<TextContent> {
    return NSFetchRequest<TextContent>(entityName: "TextContent")
  }

  @NSManaged public var id: UUID?
  @NSManaged public var encryptedContent: Data?
  @NSManaged public var item: Item?
}

extension TextContent: Identifiable {

}
