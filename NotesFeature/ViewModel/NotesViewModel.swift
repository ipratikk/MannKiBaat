//
//  NotesViewModel.swift
//  MannKiBaat
//

import Combine
import Foundation
import SwiftUI
import SwiftData
import SharedModels

@MainActor
public class NotesViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedTags: Set<String> = []

    public init() {}

    // Filtering notes
    public func filteredNotes(from notes: [NoteModel]) -> [NoteModel] {
        var result = notes

        if !searchText.isEmpty {
            let terms = searchText.lowercased().split(separator: " ").map { String($0) }
            result = result.filter { note in
                note.title.lowercased().contains(searchText.lowercased()) ||
                terms.contains(where: { note.attributedContent.string.lowercased().contains($0) }) ||
                !note.tags.isDisjoint(with: Set(terms))
            }
        }

        if !selectedTags.isEmpty {
            result = result.filter { !$0.tags.isDisjoint(with: selectedTags) }
        }

        result.sort { $0.createdAt > $1.createdAt }
        return result
    }
    
    @MainActor
    func groupedNotes(_ notes: [NoteModel]) -> [String: [NoteModel]] {
        var sections: [String: [NoteModel]] = [:]
        let calendar = Calendar.current
        let now = Date()
        
        for note in notes {
            let date = note.createdAt
            let title: String
            
            if date.isToday() {
                title = "Today • \(date.timeString())"
            } else if date.isYesterday() {
                title = "Yesterday • \(date.timeString())"
            } else if let daysAgo = date.daysAgo(), daysAgo <= 30 {
                title = date.dayMonthYearString()  // e.g., Aug 15
            } else if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
                title = date.monthYearString()
            } else {
                title = date.yearString()
            }
            
            sections[title, default: []].append(note)
        }
        
        for key in sections.keys {
            sections[key]?.sort { $0.createdAt > $1.createdAt }
        }
        
        return sections
    }



    // MARK: - CRUD
    public func addNote(_ note: NoteModel, in context: ModelContext) async {
        context.insert(note)
        try? await context.save()
    }

    public func updateNote(_ note: NoteModel, in context: ModelContext) async {
        try? await context.save()
    }

    public func removeNote(_ note: NoteModel, in context: ModelContext) async {
        context.delete(note)
        try? await context.save()
    }

    public func refresh(_ context: ModelContext) async {
        try? await context.save()
    }
}
