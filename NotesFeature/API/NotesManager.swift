//
//  NotesManager.swift
//  NotesFeature
//

import Combine
import SwiftData
import SharedModels
import Foundation

@MainActor
public class NotesManager: ObservableObject {
    @Published public var notes: [NoteModel] = []

    private let container: ModelContext
    private let syncService: NotesSyncing

    public init(container: ModelContext, syncService: NotesSyncing) {
        self.container = container
        self.syncService = syncService
        Task { await fetchLocalNotes() }
    }

    // MARK: - Fetch Local Notes
    private func fetchLocalNotes() async {
        do {
            let descriptor = FetchDescriptor<NoteModel>(sortBy: [SortDescriptor(\.createdAt, order: .forward)])
            notes = try container.fetch(descriptor)
        } catch {
            print("Failed to fetch local notes: \(error)")
            notes = []
        }
    }

    // MARK: - Fetch All Notes (Local + Remote Sync)
    public func fetchNotes() async {
        await fetchLocalNotes()
        
        // Sync remote notes from CloudKit
        let remoteNotes = await syncService.fetchNotes()
        
        // Merge remote notes with local, avoid duplicates
        for remoteNote in remoteNotes {
            if !notes.contains(where: { $0.id == remoteNote.id }) {
                container.insert(remoteNote)
            }
        }
        
        do {
            try container.save()
            await fetchLocalNotes()
        } catch {
            print("Failed to save merged notes: \(error)")
        }
    }

    // MARK: - Add Note
    public func addNote(_ note: NoteModel) async {
        container.insert(note)
        do {
            try container.save()
            await fetchLocalNotes()
        } catch {
            print("Failed to save note: \(error)")
        }

        // Sync to CloudKit
        await syncService.syncNotes([note])
    }

    // MARK: - Remove Note
    public func removeNote(_ note: NoteModel) async {
        container.delete(note)
        do {
            try container.save()
            await fetchLocalNotes()
        } catch {
            print("Failed to delete note locally: \(error)")
        }

        // Delete from CloudKit
        await syncService.deleteNotes([note])
    }
}
