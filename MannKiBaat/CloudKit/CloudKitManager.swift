//
//  CloudKitManager.swift
//  MannKiBaat
//

import Foundation
import CloudKit
import Combine
import SwiftUI

@MainActor
final class CloudKitManager: ObservableObject {
    static let shared = CloudKitManager()
    private let db = CKContainer.default().privateCloudDatabase

    @Published var notes: [CKRecord] = []
    @Published var errorMessage: String?

    private init() {}

    // MARK: - Save a note with optional media
    func saveNote(title: String?, content: String, mediaData: Data? = nil, mediaFileExtension: String = "jpg") async {
        let record = CKRecord(recordType: "Note")
        record["title"] = title as CKRecordValue?
        record["content"] = content as CKRecordValue?
        record["createdAt"] = Date() as CKRecordValue

        if let data = mediaData {
            let filename = UUID().uuidString + "." + mediaFileExtension
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            do {
                try data.write(to: url)
                record["media"] = CKAsset(fileURL: url)
            } catch {
                errorMessage = error.localizedDescription
                return
            }
        }

        do {
            let savedRecord = try await db.save(record)
            notes.append(savedRecord)

            // Cleanup temp file
            if let asset = savedRecord["media"] as? CKAsset, let fileUrl = asset.fileURL {
                try? FileManager.default.removeItem(at: fileUrl)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Fetch notes using async/await
    func fetchNotes() async {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Note", predicate: predicate)

        do {
            let (matchedResults, _) = try await db.records(matching: query)
            var fetched: [CKRecord] = []

            for (_, result) in matchedResults {
                switch result {
                case .success(let record):
                    fetched.append(record)
                case .failure(let error):
                    print("Error fetching record: \(error.localizedDescription)")
                }
            }

            notes = fetched
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Fetch media
    func fetchMedia(from record: CKRecord, key: String = "media") async throws -> Data {
        guard let asset = record[key] as? CKAsset, let url = asset.fileURL else {
            throw NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "No asset found"])
        }
        return try Data(contentsOf: url)
    }
}
