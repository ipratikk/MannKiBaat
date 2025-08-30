//
//  NotesManager.swift
//  NotesFeature
//
//  Created by Pratik Goel on 30/08/25.
//

import Combine
import SwiftData
import Foundation
import SharedModels

@MainActor
public class NotesManager: ObservableObject {
    
    @Published public var notes: [NoteModel] = []

    private let container: ModelContext
    private let syncService: NotesSyncing

    public init(container: ModelContext, syncService: NotesSyncing) {
        self.container = container
        self.syncService = syncService
        fetchLocalNotes()
    }

    // MARK: - Fetch local notes
    private func fetchLocalNotes() {
        do {
            let descriptor = FetchDescriptor<NoteModel>(
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            notes = try container.fetch(descriptor)
        } catch {
            print("Failed to fetch notes locally: \(error)")
            notes = []
        }
    }

    // MARK: - Fetch from CloudKit + merge with local
    public func fetchNotes() async {
        // Fetch from CloudKit
        let cloudNotes = await syncService.fetchNotes()
        
        // Merge with local storage
        for note in cloudNotes {
            if !notes.contains(where: { $0.id == note.id }) {
                container.insert(note)
            }
        }

        do {
            try container.save()
            fetchLocalNotes()
        } catch {
            print("Failed to save merged notes: \(error)")
        }
    }

    // MARK: - Add note
    public func addNote(_ note: NoteModel) async {
        container.insert(note)
        do {
            try container.save()
            fetchLocalNotes()
        } catch {
            print("Failed to save note locally: \(error)")
        }

        // Sync to CloudKit
        await syncService.syncNotes([note])
    }

    // MARK: - Remove note
    public func removeNote(_ note: NoteModel) async {
        container.delete(note)
        do {
            try container.save()
            fetchLocalNotes()
        } catch {
            print("Failed to delete note locally: \(error)")
        }

        // Sync deletion to CloudKit
        await syncService.deleteNotes([note])
    }
}
