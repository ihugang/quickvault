//
//  Item+CoreDataClass.swift
//  QuickVault
//

import CoreData
import Foundation

@objc(Item)
public class Item: NSManagedObject {
  
  // MARK: - Computed Properties
  
  public var tags: [String] {
    get {
      guard let tagsJSON = tagsJSON,
            let data = tagsJSON.data(using: .utf8),
            let array = try? JSONDecoder().decode([String].self, from: data) else {
        return []
      }
      return array
    }
    set {
      if let data = try? JSONEncoder().encode(newValue),
         let string = String(data: data, encoding: .utf8) {
        tagsJSON = string
      } else {
        tagsJSON = nil
      }
    }
  }
}
