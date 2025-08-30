//
//  NotesManager.swift
//  NotesFeature
//
//  Created by Pratik Goel on 30/08/25.
//

import Foundation
import Combine
import SharedModels

@MainActor
public class NotesManager: ObservableObject {
    @Published public private(set) var notes: [Note] = []
    private let syncService: NotesSyncing

    public init(syncService: NotesSyncing) {
        self.syncService = syncService
    }

    // Add note (UI updates immediately)
    public func addNote(_ note: Note) {
        notes.append(note)

        // Fire-and-forget CloudKit sync
        Task {
            await syncService.syncNotes([note])
        }
    }

    // Remove note
    public func removeNote(at index: Int) {
        guard notes.indices.contains(index) else { return }
        let removed = notes.remove(at: index)

        Task {
            // Optionally sync deletion with CloudKit
            await syncService.deleteNotes([removed])
        }
    }

    // Fetch remote notes
    public func fetchNotes() async {
        let fetched = await syncService.fetchNotes()
        notes = fetched
    }
}
