//
//  NotesSyncing.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import Foundation
import SharedModels

public protocol NotesSyncing {
    func syncNotes(_ notes: [NoteModel]) async
    func deleteNotes(_ notes: [NoteModel]) async
    func fetchNotes() async -> [NoteModel]
}
