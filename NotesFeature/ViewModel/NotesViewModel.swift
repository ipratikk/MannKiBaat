//
//  NotesViewModel.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import Combine
import SwiftUI
import Foundation
import SwiftData
import SharedModels

@MainActor
public class NotesViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedTags: Set<String> = []
    @Published var sortAscending: Bool = false
    
    public init() {}
    
    public func filteredNotes(from notes: [NoteModel]) -> [NoteModel] {
        var result = notes
        
        if !searchText.isEmpty {
            result = result.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText) ||
                !note.tags.isDisjoint(with: Set(searchText.split(separator: " ").map { String($0) }))
            }
        }
        
        if !selectedTags.isEmpty {
            result = result.filter { !$0.tags.isDisjoint(with: selectedTags) }
        }
        
        result.sort { sortAscending ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt }
        return result
    }
    
    // MARK: - CRUD
    public func addNote(_ note: NoteModel, in context: ModelContext) async {
        await context.insert(note)
        try? await context.save()
    }
    
    public func updateNote(_ note: NoteModel, in context: ModelContext) async {
        try? await context.save()
    }
    
    public func removeNote(_ note: NoteModel, in context: ModelContext) async {
        context.delete(note)
        try? await context.save()
    }
    
    public func refreshNotes() async {
        // Save to trigger CloudKit sync
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
}
