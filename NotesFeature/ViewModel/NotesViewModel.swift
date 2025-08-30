//
//  NotesViewModel.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import Combine
import Foundation
import SwiftData
import SharedModels

@MainActor
public class NotesViewModel: ObservableObject {
    @Published public var searchText: String = ""
    @Published public var sortAscending: Bool = false
    @Published public var selectedTags: Set<String> = []

    public init() {}

    // Filter notes from @Query in NotesView
    public func filteredNotes(from notes: [NoteModel]) -> [NoteModel] {
        var result = notes

        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { note in
                note.title.localizedCaseInsensitiveContains(searchText) ||
                note.content.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter by selected tags
        if !selectedTags.isEmpty {
            result = result.filter { note in
                !Set(note.tags).isDisjoint(with: selectedTags)
            }
        }

        // Sort
        result.sort {
            sortAscending ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt
        }

        return result
    }

    // MARK: - Note operations

    public func addNote(_ note: NoteModel, in context: ModelContext) async {
        context.insert(note)
        try? context.save()
    }

    public func removeNote(_ note: NoteModel, in context: ModelContext) async {
        context.delete(note)
        try? context.save()
    }

    public func refreshNotes() async {
        // @Query automatically observes CloudKit changes.
        // Can trigger any lightweight action if needed.
    }
}
