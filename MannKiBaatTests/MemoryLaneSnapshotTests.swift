//
//  MemoryLaneSnapshotTests.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 14/04/26.
//

import XCTest
import SnapshotTesting
import SwiftUI
import SwiftData
@testable import MannKiBaat
import SharedModels
import NotesFeature

@MainActor
final class MemoryLaneSnapshotTests: XCTestCase {
    
    let record = true
    
    private func makeMockContainer(fileName: String) -> ModelContainer {
        ModelContainer.mock(fileName: fileName)
    }
    
    private func makeView(fileName: String) -> some View {
        let container = makeMockContainer(fileName: fileName)
        
        let context = container.mainContext
        let lanes = (try? context.fetch(FetchDescriptor<MemoryLane>())) ?? []
        
        guard let lane = lanes.first else {
            fatalError("❌ No MemoryLane found. Ensure mock JSON seeds a lane.")
        }
        
        let viewModel = MemoryViewModel()
        
        return MemoryLaneView(lane: lane, viewModel: viewModel)
        .modelContainer(container)
    }
    
    func test_memory_lane_normal() {
        verifySnapshots(makeView(fileName: "mock_data"), record: record)
    }
}
