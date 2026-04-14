//
//  ModelContainer+Mock.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 13/04/26.
//

import Foundation
import SharedModels
import SwiftData

extension ModelContainer {
    
    @MainActor
    static func mock(fileName: String = "mock_data") -> ModelContainer {
        let schema = Schema([
            NoteModel.self
        ])
        
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        let container = try! ModelContainer(
            for: schema,
            configurations: [config]
        )
        
        seedMockData(in: container, fileName: fileName)
        
        return container
    }
    
    @MainActor
    private static func seedMockData(in container: ModelContainer, fileName: String) {
        let context = container.mainContext
        
        let bundleCandidates: [Bundle] = [
            Bundle.main,
            Bundle(for: BundleToken.self)
        ]
        
        let url = bundleCandidates
            .compactMap { $0.url(forResource: fileName, withExtension: "json") }
            .first
        
        guard let fileURL = url,
              let data = try? Data(contentsOf: fileURL) else {
            assertionFailure("❌ Failed to load \(fileName).json")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            
            let mockData = try decoder.decode(MockData.self, from: data)
            
            // MARK: - Notes
            for note in mockData.notes {
                let model = NoteModel()
                model.title = note.title
                model.createdAt = note.createdAt
                
                context.insert(model)
            }
            try? context.save()
            
        } catch {
            assertionFailure("❌ Failed to decode mock JSON: \(error)")
        }
    }
    
    private final class BundleToken {}
}
