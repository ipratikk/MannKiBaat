//
//  SyncManager.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import Foundation
import CloudKitFeature
import SharedModels

@MainActor
public class SyncManager: NotesSyncing {
    public init() {}

    public func syncNotes(_ notes: [NoteModel]) async {
        for note in notes {
            try? await CloudKitService().saveNote(note)
        }
    }

    public func deleteNotes(_ notes: [NoteModel]) async {
        for note in notes {
            try? await CloudKitService().deleteNote(note)
        }
    }

    public func fetchNotes() async -> [NoteModel] {
        return (try? await CloudKitService().fetchNotes()) ?? []
    }
}
