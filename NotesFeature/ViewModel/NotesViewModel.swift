//
//  NotesViewModel.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import Foundation
import Combine
import SwiftUI
import SharedModels

@MainActor
public class NotesViewModel: ObservableObject {
    @Published public var notes: [Note] = []              // All notes
    @Published public var displayedNotes: [Note] = []     // Filtered + sorted notes

    @Published public var errorMessage: String?

    @Published public var searchText: String = ""         // Search input
    @Published public var selectedTags: Set<String> = []  // Filter tags
    @Published public var sortAscending: Bool = true      // Sort by createdAt

    private let notesManager: NotesManager

    public init(notesManager: NotesManager) {
        self.notesManager = notesManager
        self.notes = notesManager.notes
        self.displayedNotes = notesManager.notes
    }

    // Fetch notes from sync service
    public func fetchNotes() async {
        await notesManager.fetchNotes()
        self.notes = notesManager.notes
        await applyFilters()
    }

    // Add new note
    public func addNote(_ note: Note) async {
        notesManager.addNote(note)
        self.notes = notesManager.notes
        await applyFilters()
    }

    // Remove note
    public func removeNote(at index: Int) {
        notesManager.removeNote(at: index)
        self.notes = notesManager.notes
        Task { await applyFilters() }
    }

    // Apply search, tag filter, and sorting
    public func applyFilters() async {
        // Capture MainActor-isolated properties
        let notesCopy = notes
        let searchTextCopy = searchText
        let selectedTagsCopy = selectedTags
        let sortAscendingCopy = sortAscending

        // Run heavy filtering/sorting off the main thread
        let filtered = await Task.detached(priority: .userInitiated) {
            notesCopy.filter { note in
                let matchesSearch = searchTextCopy.isEmpty ||
                    note.title.localizedCaseInsensitiveContains(searchTextCopy) ||
                    note.content.localizedCaseInsensitiveContains(searchTextCopy) ||
                    note.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchTextCopy) })

                let matchesTags = selectedTagsCopy.isEmpty ||
                    !selectedTagsCopy.isDisjoint(with: note.tags)

                return matchesSearch && matchesTags
            }
            .sorted { sortAscendingCopy ? $0.createdAt < $1.createdAt : $0.createdAt > $1.createdAt }
        }.value

        // Update MainActor property
        await MainActor.run {
            self.displayedNotes = filtered
        }
    }

}
