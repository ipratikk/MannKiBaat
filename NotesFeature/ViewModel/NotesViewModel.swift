//
//  NotesViewModel.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import Combine
import SwiftUI
import SharedModels

@MainActor
public class NotesViewModel: ObservableObject {
    @Published public var notes: [NoteModel] = []
    @Published public var displayedNotes: [NoteModel] = []

    @Published public var searchText: String = ""
    @Published public var selectedTags: Set<String> = []
    @Published public var sortAscending: Bool = true

    private let notesManager: NotesManager

    public init(notesManager: NotesManager) {
        self.notesManager = notesManager
        self.notes = notesManager.notes
        self.displayedNotes = notesManager.notes
    }

    public func fetchNotes() async {
        await notesManager.fetchNotes()
        notes = notesManager.notes
        await applyFilters()
    }

    public func addNote(_ note: NoteModel) async {
        await notesManager.addNote(note)
        notes = notesManager.notes
        await applyFilters()
    }

    public func removeNote(_ note: NoteModel) async {
        await notesManager.removeNote(note)
        notes = notesManager.notes
        await applyFilters()
    }

    public func applyFilters() async {
        let notesCopy = notes
        let search = searchText
        let tags = selectedTags
        let ascending = sortAscending

        let filtered = await Task.detached(priority: .userInitiated) {
            notesCopy.filter { note in
                let matchesSearch = search.isEmpty ||
                    note.title.localizedCaseInsensitiveContains(search) ||
                    note.content.localizedCaseInsensitiveContains(search) ||
                    note.tags.contains(where: { $0.localizedCaseInsensitiveContains(search) })

                let matchesTags = tags.isEmpty || !tags.isDisjoint(with: note.tags)
                return matchesSearch && matchesTags
            }
            .sorted { ascending ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt }
        }.value

        await MainActor.run {
            displayedNotes = filtered
        }
    }

}
