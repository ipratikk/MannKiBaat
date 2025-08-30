//
//  CloudKitManager.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import CloudKit
import SharedModels
import Combine

@MainActor
public class CloudKitManager {
    public static let shared = CloudKitManager()
    private let container: CKContainer
    private let database: CKDatabase

    @Published public var notes: [NoteModel] = []

    private init(containerIdentifier: String = "iCloud.com.pratik.MannKiBaat") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
    }

    public func saveNote(_ note: NoteModel) async {
        let record = CKRecord(recordType: "Note")
        record["id"] = note.id.uuidString as CKRecordValue
        record["title"] = note.title as CKRecordValue
        record["content"] = note.content as CKRecordValue
        record["tags"] = Array(note.tags) as CKRecordValue
        record["createdAt"] = note.createdAt as CKRecordValue

        do {
            let _ = try await database.save(record)
            if !notes.contains(note) {
                notes.append(note)
            }
        } catch {
            print("CloudKit save error: \(error)")
        }
    }

    public func deleteNote(_ note: NoteModel) async {
        let recordID = CKRecord.ID(recordName: note.id.uuidString)
        do {
            try await database.deleteRecord(withID: recordID)
            notes.removeAll { $0.id == note.id }
        } catch {
            print("CloudKit delete error: \(error)")
        }
    }

    public func fetchNotes() async -> [NoteModel] {
        let query = CKQuery(recordType: "Note", predicate: NSPredicate(value: true))
        do {
            let (matchResults, _) = try await database.records(matching: query)
            let fetchedNotes = matchResults.compactMap { (_, result) -> NoteModel? in
                guard let record = try? result.get(),
                      let idString = record["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let title = record["title"] as? String,
                      let content = record["content"] as? String,
                      let tagsArray = record["tags"] as? [String],
                      let createdAt = record["createdAt"] as? Date
                else { return nil }

                return NoteModel(
                    id: id,
                    title: title,
                    content: content,
                    tags: Set(tagsArray),
                    createdAt: createdAt
                )
            }
            self.notes = fetchedNotes
            return fetchedNotes
        } catch {
            print("CloudKit fetch error: \(error)")
            return []
        }
    }
}
