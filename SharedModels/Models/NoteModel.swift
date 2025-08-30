//
//  Note.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import SwiftData
import Foundation

@Model
public class NoteModel {
    @Attribute public var id: UUID = UUID()
    @Attribute public var title: String = ""
    @Attribute public var content: String = ""
    @Attribute public var createdAt: Date = Date()
    @Attribute public var tags: Set<String> = []
    
    public init(
        id: UUID = UUID(),
        title: String = "",
        content: String = "",
        createdAt: Date = Date(),
        tags: Set<String> = []
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.tags = tags
    }
}
