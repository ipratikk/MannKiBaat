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
    
    let record = false
    
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
        .environment(\.brand, ManasaBrand())
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
            string: "Designing a Scalable Notes App\n\n",
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .largeTitle),
                .foregroundColor: UIColor.label
            ]
        )
        
        let intro = NSAttributedString(
            string: "Building a modern note-taking experience requires a strong foundation in architecture, performance, and user experience.\n\n",
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.secondaryLabel
            ]
        )
        
        let sectionHeader = NSAttributedString(
            string: "Key Highlights\n",
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .title3),
                .foregroundColor: UIColor.label
            ]
        )
        
        let bullets = NSAttributedString(
            string: "• Modular architecture for scalability\n• SwiftData for efficient persistence\n• Offline-first design with sync support\n• Optimized rendering for smooth scrolling\n• Snapshot testing for UI reliability\n\n",
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .body),
                .foregroundColor: UIColor.label
            ]
        )
        
        let emphasis = NSAttributedString(
            string: "Core Principle: ",
            attributes: [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.label
            ]
        )
        
        let principle = NSAttributedString(
            string: "Build systems that are simple to extend and hard to break.\n\n",
            attributes: [
                .font: UIFont.italicSystemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ]
        )
        
        let closing = NSAttributedString(
            string: "This approach ensures maintainability, performance, and a delightful user experience across all scenarios.",
            attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.label
            ]
        )
        
        attributed.append(intro)
        attributed.append(sectionHeader)
        attributed.append(bullets)
        attributed.append(emphasis)
        attributed.append(principle)
        attributed.append(closing)
        
        note.title = "Scalable Notes Architecture"
        
        note.attributedContent = attributed
        
        let view = NoteEditorView(
            note: note,
            viewModel: notesVM,
            isNewNote: false
        )
            .environmentObject(loginVM)
            .modelContainer(container)
            .environment(\.brand, ManasaBrand())
        
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
        
        verifySnapshots(
            view.environment(\.brand, GenericBrand()),
            record: record
        )
    }
}
