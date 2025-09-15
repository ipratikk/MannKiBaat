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
    @Attribute public var isPinned: Bool = false
    @Attribute public var createdAt: Date = Date()
    @Attribute public var updatedAt: Date = Date()
    @Attribute public var dueDate: Date? = nil
    @Attribute public var reminderDate: Date? = nil
    @Attribute public var remindBeforeMinutes: Int? = nil // optional "remind X min before"
    @Attribute public var orderIndex: Int = 0
    
    // Optional inverse relationship
    @Relationship(inverse: \TodoObject.items) public var parent: TodoObject?
    
    public init(title: String = "",
                parent: TodoObject? = nil,
                isCompleted: Bool = false,
                isPinned: Bool = false,
                createdAt: Date = Date(),
                updatedAt: Date = Date(),
                dueDate: Date? = nil,
                reminderDate: Date? = nil,
                remindBeforeMinutes: Int? = nil,
                orderIndex: Int = 0) {
        self.title = title
        self.parent = parent
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.dueDate = dueDate
        self.reminderDate = reminderDate
        self.remindBeforeMinutes = remindBeforeMinutes
        self.orderIndex = orderIndex
    }
}
