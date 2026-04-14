//
//  NotesSnapshotTests.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 14/04/26.
//

// NotesSnapshotTests.swift

import XCTest
import SnapshotTesting
import SwiftUI
import SwiftData
@testable import MannKiBaat
import SharedModels
import NotesFeature
import LoginFeature

@MainActor
final class NotesSnapshotTests: XCTestCase {
    
    let record = true
    
    private func makeMockContainer(fileName: String) -> ModelContainer {
        ModelContainer.mock(fileName: fileName)
    }
    
    private func makeView(fileName: String) -> some View {
        let container = makeMockContainer(fileName: fileName)
        
        let loginVM = LoginViewModel()
        let notesVM = NotesViewModel()
        
        return NavigationStack {
            NotesView(viewModel: notesVM)
        }
        .environmentObject(loginVM)
        .modelContainer(container)
    }
    
    func test_notes_normal() {
        verifySnapshots(makeView(fileName: "mock_data"), record: record)
    }
    
    func test_notes_heavy() {
        verifySnapshots(makeView(fileName: "mock_notes_heavy"), record: record)
    }
}
