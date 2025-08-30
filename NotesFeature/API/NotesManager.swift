//
//  NotesManager.swift
//  NotesFeature
//
//  Created by Pratik Goel on 30/08/25.
//

import Foundation
import SwiftData
import SharedModels

@MainActor
public final class NotesManager {
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Add a note
    public func addNote(_ note: NoteModel) {
        modelContext.insert(note)
    }
    
    // Delete a note
    public func removeNote(_ note: NoteModel) {
        modelContext.delete(note)
    }
    
    // Update note
    public func updateNote(_ note: NoteModel) {
        // With SwiftData, changes to note objects are auto-tracked in modelContext
        // Just save context if needed
        // modelContext.save() is automatically called on @Query updates
    }
}
