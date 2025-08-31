// NoteEditorView.swift

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
    public var isNewNote: Bool = false

    @State private var hideToolbar: Bool = true

    // Reference to UIKit editor to trigger Done action
    @State private var editorVC: NoteEditorViewController?

    public init(note: NoteModel, viewModel: NotesViewModel, isNewNote: Bool = false) {
        self.note = note
        self.viewModel = viewModel
        self.isNewNote = isNewNote
    }

    public var body: some View {
        NoteEditorViewControllerRepresentable(
            note: isNewNote ? NoteModel() : note,
            viewModel: viewModel,
            modelContext: modelContext,
            isNewNote: isNewNote,
            onDismiss: {
                hideToolbar = false
                dismiss()
            },
            editorVC: $editorVC
        )
        .navigationTitle("Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    editorVC?.endEditing()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                }
            }
        }
        .toolbar(hideToolbar ? .hidden : .visible, for: .tabBar)
        .onAppear {
            hideToolbar = true
        }
    }
}

// MARK: - UIViewControllerRepresentable Wrapper
@MainActor
struct NoteEditorViewControllerRepresentable: UIViewControllerRepresentable {
    let note: NoteModel
    @ObservedObject var viewModel: NotesViewModel
    var modelContext: ModelContext
    var isNewNote: Bool
    var onDismiss: () -> Void

    @Binding var editorVC: NoteEditorViewController?

    func makeUIViewController(context: Context) -> NoteEditorViewController {
        let vc = NoteEditorViewController(note: note, viewModel: viewModel, modelContext: modelContext, isNewNote: isNewNote)
        vc.onDismiss = onDismiss
        DispatchQueue.main.async {
            editorVC = vc
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: NoteEditorViewController, context: Context) {
        uiViewController.note = note
    }
}
