//
//  ModelContainer+Mock.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 13/04/26.
//

import Foundation
import SharedModels
import SwiftData
import UIKit

extension ModelContainer {
    
    @MainActor
    static func mock(fileName: String = "mock_data") -> ModelContainer {
        let schema = Schema([
            NoteModel.self,
            MemoryLane.self,
            MemoryItem.self
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
            
            // MARK: - Memory Lane
            let lane = MemoryLane(title: "Startup Journey", createdAt: Date())
            context.insert(lane)
            
            for memory in mockData.memories {
                let images: [Data] = {
                    // Try base64 first
                    if let base64 = memory.imageDatas,
                       !base64.isEmpty {
                        let decoded = base64.compactMap { Data(base64Encoded: $0) }
                        if !decoded.isEmpty {
                            return decoded
                        }
                    }
                    
                    // Fallback to asset image
                    if let name = memory.imageName,
                       let image = UIImage(named: name),
                       let data = image.jpegData(compressionQuality: 0.7) {
                        return [data]
                    }
                    
                    return []
                }()
                
                let item = MemoryItem(
                    title: memory.title,
                    details: memory.content,
                    createdAt: memory.createdAt,
                    imageDatas: images,
                    parent: lane
                )
                
                lane.items = (lane.items ?? []) + [item]
                context.insert(item)
            }
            
        } catch {
            assertionFailure("❌ Failed to decode mock JSON: \(error)")
        }
    }
    
    private final class BundleToken {}
}
