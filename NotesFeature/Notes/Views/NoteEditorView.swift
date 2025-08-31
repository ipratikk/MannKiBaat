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
    @State private var isEditing: Bool = false

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
            isTextEditing: $isEditing,
            modelContext: modelContext,
            isNewNote: isNewNote,
            onDismiss: {
                hideToolbar = false
                dismiss()
            },
            editorVC: $editorVC
        )
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editorVC?.removeNote()
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .tint(Color.red)
                }
            }
            if isEditing {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        editorVC?.endEditing()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                    }
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
    @Binding var isTextEditing: Bool
    var modelContext: ModelContext
    var isNewNote: Bool
    var onDismiss: () -> Void

    @Binding var editorVC: NoteEditorViewController?

    func makeUIViewController(context: Context) -> NoteEditorViewController {
        let vc = NoteEditorViewController(note: note, viewModel: viewModel, modelContext: modelContext, isNewNote: isNewNote)
        vc.onDismiss = onDismiss
        vc.onEditingChanged = { editing in
            DispatchQueue.main.async {
                self.isTextEditing = editing
            }
        }
        DispatchQueue.main.async {
            editorVC = vc
        }
        return vc
    }

    func updateUIViewController(_ uiViewController: NoteEditorViewController, context: Context) {
        uiViewController.note = note
    }
}
