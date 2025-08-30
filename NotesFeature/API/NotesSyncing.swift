//
//  NotesSyncing.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//


import Foundation
import SharedModels

@MainActor
public protocol NotesSyncing {
    /// Sync new or updated notes
    func syncNotes(_ notes: [Note]) async
    
    /// Fetch all notes
    func fetchNotes() async -> [Note]

    /// Delete notes remotely
    func deleteNotes(_ notes: [Note]) async
}
