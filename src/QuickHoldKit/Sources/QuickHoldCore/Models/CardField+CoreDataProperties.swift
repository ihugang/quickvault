//
//  CardField+CoreDataProperties.swift
//  QuickHold
//

import CoreData
import Foundation

extension CardField {
  @nonobjc public class func fetchRequest() -> NSFetchRequest<CardField> {
    return NSFetchRequest<CardField>(entityName: "CardField")
  }

  @NSManaged public var id: UUID
  @NSManaged public var key: String
  @NSManaged public var label: String
  @NSManaged public var encryptedValue: Data
  @NSManaged public var order: Int16
  @NSManaged public var isCopyable: Bool
  @NSManaged public var card: Card?
}

extension CardField: Identifiable {

}
