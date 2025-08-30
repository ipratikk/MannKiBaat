//
//  NewNoteView.swift
//  MannKiBaat
//

import SwiftUI
import SharedModels
import SwiftData

@MainActor
public struct NewNoteView: View {
    @ObservedObject var viewModel: NotesViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var content = ""
    @State private var tagsText = ""

    public init(viewModel: NotesViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Enter title", text: $title)
                }

                Section("Content") {
                    TextEditor(text: $content)
                        .frame(minHeight: 100)
                }

                Section("Tags (comma separated)") {
                    TextField("tag1, tag2, tag3", text: $tagsText)
                }
            }
            .navigationTitle("New Note")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveNote) {
                        Text("Save")
                    }
                    .disabled(title.isEmpty && content.isEmpty)
                }
            }
        }
    }

    private func saveNote() {
        Task {
            let tags = tagsText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            let note = NoteModel(
                title: title,
                content: content,
                tags: Set(tags)
            )

            await viewModel.addNote(note, in: modelContext)
            dismiss()
        }
    }
}
