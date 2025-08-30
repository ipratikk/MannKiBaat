//
//  CloudKitService.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import CloudKit
import SharedModels

public class CloudKitService {
    private let container: CKContainer
    private let database: CKDatabase

    public init(containerIdentifier: String = "iCloud.com.pratik.MannKiBaat") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
    }

    // Save note
    public func saveNote(_ note: Note) async throws -> Note {
        let record = CKRecord(recordType: "Note")
        record["id"] = note.id.uuidString as CKRecordValue
        record["title"] = note.title as CKRecordValue
        record["content"] = note.content as CKRecordValue
        record["tags"] = Array(note.tags) as CKRecordValue
        record["createdAt"] = note.createdAt as CKRecordValue

        let _ = try await database.save(record)
        return note
    }

    // Fetch notes
    public func fetchNotes() async throws -> [Note] {
        let query = CKQuery(recordType: "Note", predicate: NSPredicate(value: true))
        let (matchResults, _) = try await database.records(matching: query)

        let records = matchResults.compactMap { (_, result) -> CKRecord? in
            try? result.get()
        }

        return records.compactMap { record in
            guard
                let idString = record["id"] as? String,
                let id = UUID(uuidString: idString),
                let title = record["title"] as? String,
                let content = record["content"] as? String,
                let tagsArray = record["tags"] as? [String],
                let createdAt = record["createdAt"] as? Date
            else { return nil }

            return Note(
                id: id,
                title: title,
                content: content,
                tags: Set(tagsArray),
                createdAt: createdAt
            )
        }
    }
    
    public func deleteNote(_ note: Note) async throws {
        let recordID = CKRecord.ID(recordName: note.id.uuidString)
        try await database.deleteRecord(withID: recordID)
    }

}
