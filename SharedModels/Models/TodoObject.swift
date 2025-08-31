//
//  TodoObject.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 31/08/25.
//


import SwiftData
import Foundation

@Model
public class TodoObject: Identifiable {
    @Attribute public var id: UUID = UUID()
    @Attribute public var title: String = ""
    @Attribute public var createdAt: Date = Date()
    
    // Must be optional for CloudKit
    @Relationship(deleteRule: .cascade) public var items: [TodoItem]? = nil
    
    public init(id: UUID = UUID(),
                title: String = "",
                createdAt: Date = Date(),
                items: [TodoItem]? = nil) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.items = items
    }
}

@Model
public class TodoItem: Identifiable {
    @Attribute public var id: UUID = UUID()
    @Attribute public var title: String = ""
    @Attribute public var isCompleted: Bool = false
    @Attribute public var createdAt: Date = Date()
    
    // Optional inverse relationship
    @Relationship(inverse: \TodoObject.items) public var parent: TodoObject?
    
    public init(id: UUID = UUID(),
                title: String = "",
                isCompleted: Bool = false,
                createdAt: Date = Date(),
                parent: TodoObject? = nil) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.parent = parent
    }

}
