//
//  SyncManager.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import Foundation
import SharedModels
import CloudKitFeature

@MainActor
public class SyncManager: NotesSyncing {
    public init() {}

    public func syncNotes(_ notes: [Note]) async {
        for note in notes {
            await CloudKitManager.shared.saveNote(note)
        }
    }

    public func deleteNotes(_ notes: [Note]) async {
        for note in notes {
            // Implement delete logic in CloudKitManager
            await CloudKitManager.shared.deleteNote(note)
        }
    }

    public func fetchNotes() async -> [Note] {
        await CloudKitManager.shared.fetchNotes()
        return CloudKitManager.shared.notes
    }
}
