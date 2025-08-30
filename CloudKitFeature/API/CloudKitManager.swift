//
//  CloudKitManager.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import Foundation
import Combine
import SharedModels

@MainActor
public class CloudKitManager: ObservableObject {
    public static let shared = CloudKitManager()
    private let service = CloudKitService()

    @Published public var notes: [Note] = []
    @Published public var errorMessage: String?

    private init() {}

    public func saveNote(_ note: Note) async {
        do {
            let saved = try await service.saveNote(note)
            notes.append(saved)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func fetchNotes() async {
        do {
            let fetched = try await service.fetchNotes()
            notes = fetched
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    @MainActor
    public func deleteNote(_ note: Note) async {
        do {
            try await service.deleteNote(note)
            notes.removeAll { $0.id == note.id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    
}
