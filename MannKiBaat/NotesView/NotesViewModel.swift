//
//  NotesViewModel.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//


import SwiftUI
import CloudKit
import Combine

@MainActor
class NotesViewModel: ObservableObject {
    @Published var notes: [CKRecord] = []
    @Published var errorMessage: String?

    func saveNote(title: String, content: String) async {
        await CloudKitManager.shared.saveNote(title: title, content: content)
        await fetchNotes() // refresh after save
    }

    func fetchNotes() async {
        await CloudKitManager.shared.fetchNotes()
        self.notes = CloudKitManager.shared.notes
        self.errorMessage = CloudKitManager.shared.errorMessage
    }
}
