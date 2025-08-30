//
//  Note.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import SwiftData
import Foundation

@Model
public class NoteModel: Identifiable {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var content: String
    public var tags: Set<String>
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        content: String,
        tags: Set<String> = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.tags = tags
        self.createdAt = createdAt
    }
}
