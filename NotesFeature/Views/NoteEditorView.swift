//
//  NoteEditorView.swift
//  MannKiBaat
//

import SwiftUI
import SwiftData
import SharedModels
import UIKit

@MainActor
public struct NoteEditorView: View {
    @ObservedObject public var viewModel: NotesViewModel
    @Bindable public var note: NoteModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    public init(note: NoteModel, viewModel: NotesViewModel) {
        self.note = note
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationView {
            NoteEditorViewControllerRepresentable(
                note: note,
                viewModel: viewModel,
                modelContext: modelContext,
                onDismiss: { dismiss() }
            )
            .edgesIgnoringSafeArea(.all)
            .navigationBarHidden(true)
        }
    }
}

// MARK: - UIViewControllerRepresentable Wrapper
@MainActor
struct NoteEditorViewControllerRepresentable: UIViewControllerRepresentable {
    let note: NoteModel
    @ObservedObject var viewModel: NotesViewModel
    var modelContext: ModelContext
    var onDismiss: () -> Void

    func makeUIViewController(context: Context) -> NoteEditorViewController {
        let vc = NoteEditorViewController(note: note, viewModel: viewModel, modelContext: modelContext)
        vc.onDismiss = onDismiss
        return vc
    }

    func updateUIViewController(_ uiViewController: NoteEditorViewController, context: Context) {
        uiViewController.note = note
    }
}
