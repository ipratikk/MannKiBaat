//
//  CloudKitService.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import CloudKit
import Foundation
import SharedModels

public class CloudKitService {
    private let container: CKContainer
    private let database: CKDatabase

    public init(containerIdentifier: String = "iCloud.com.pratik.MannKiBaat") {
        self.container = CKContainer(identifier: containerIdentifier)
        self.database = container.privateCloudDatabase
    }

    public func saveNote(_ note: NoteModel) async throws {
        let record = CKRecord(recordType: "Note")
        record["id"] = note.id.uuidString as CKRecordValue
        record["title"] = note.title as CKRecordValue
        record["content"] = note.content as CKRecordValue
        record["tags"] = Array(note.tags) as CKRecordValue
        record["createdAt"] = note.createdAt as CKRecordValue

        _ = try await database.save(record)
    }

    public func deleteNote(_ note: NoteModel) async throws {
        let recordID = CKRecord.ID(recordName: note.id.uuidString)
        try await database.deleteRecord(withID: recordID)
    }

    public func fetchNotes() async throws -> [NoteModel] {
        let query = CKQuery(recordType: "Note", predicate: NSPredicate(value: true))
        let (matchResults, _) = try await database.records(matching: query)

        return matchResults.compactMap { (_, result) -> NoteModel? in
            guard let record = try? result.get(),
                  let idString = record["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let title = record["title"] as? String,
                  let content = record["content"] as? String,
                  let tagsArray = record["tags"] as? [String],
                  let createdAt = record["createdAt"] as? Date
            else { return nil }

            return NoteModel(id: id, title: title, content: content, tags: Set(tagsArray), createdAt: createdAt)
        }
    }
}
