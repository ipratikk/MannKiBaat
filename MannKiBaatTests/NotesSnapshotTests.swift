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
    
    // MARK: - Note Detail / Editor
    func test_note_detail() {
        let container = makeMockContainer(fileName: "mock_data")
        
        let loginVM = LoginViewModel()
        let notesVM = NotesViewModel()
        
        let context = container.mainContext
        let notes = (try? context.fetch(FetchDescriptor<NoteModel>())) ?? []
        guard let note = notes.first else { return }
        
        // Inject meaningful content with formatting
        let attributed = NSMutableAttributedString(
            string: "Scaling Ideas\n\n",
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .title2),
                .foregroundColor: UIColor.label
            ]
        )
        
        let body = NSAttributedString(
            string: "• Use modular architecture\n• Add caching layer\n• Optimize SwiftData queries\n• Add offline sync support\n• Improve performance with batching\n\n",
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.label
            ]
        )
        
        let heading = NSAttributedString(
            string: "Architecture Notes\n",
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .title3),
                .foregroundColor: UIColor.label
            ]
        )
        
        let italic = NSAttributedString(
            string: "Focus on scalability and maintainability.\n\n",
            attributes: [
                .font: UIFont.italicSystemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ]
        )
        
        let bold = NSAttributedString(
            string: "Key Insight: ",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.label
            ]
        )
        
        let normal = NSAttributedString(
            string: "Separation of concerns improves maintainability.",
            attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ]
        )
        
        attributed.append(heading)
        attributed.append(body)
        attributed.append(italic)
        attributed.append(bold)
        attributed.append(normal)
        
        note.title = "Scaling architecture"
        note.attributedContent = attributed
        
        
        let view = NoteEditorView(
            note: note,
            viewModel: notesVM,
            isNewNote: false
        )
            .environmentObject(loginVM)
            .modelContainer(container)
            .onAppear {
                note.attributedContent = attributed
            }
        
        verifySnapshots(view, record: record)
    }
    
    // MARK: - Auth / FaceID Screen
    func test_auth_screen() {
        let loginVM = LoginViewModel()
        let namespace = Namespace().wrappedValue
        
        let view = LoginView(
            viewModel: loginVM,
            namespace: namespace,
            showContent: .constant(true)
        )
        
        verifySnapshots(view, record: record)
    }
}
