//
//  NoteEditorView.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 31/08/25.
//

import SwiftUI
import SwiftData
import SharedModels

@MainActor
public struct NoteEditorView: View {
    @ObservedObject var viewModel: NotesViewModel
    let note: NoteModel? // Keep optional, no @ObservedObject
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var content: String
    @State private var tagsText: String

    public init(note: NoteModel? = nil, viewModel: NotesViewModel) {
        self.note = note
        self.viewModel = viewModel
        _title = State(initialValue: note?.title ?? "")
        _content = State(initialValue: note?.content ?? "")
        _tagsText = State(initialValue: note?.tags.joined(separator: ", ") ?? "")
    }

    public var body: some View {
        Form {
            Section("Title") {
                TextField("Enter title", text: $title)
            }

            Section("Content") {
                TextEditor(text: $content)
                    .frame(minHeight: 100)
            }

            Section("Tags (comma separated)") {
                TextField("tag1, tag2", text: $tagsText)
            }
        }
        .navigationTitle(note == nil ? "New Note" : "Edit Note")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    Task {
                        let tags = tagsText
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }

                        if let existingNote = note {
                            existingNote.title = title
                            existingNote.content = content
                            existingNote.tags = Set(tags)
                            await viewModel.updateNote(existingNote, in: modelContext)
                        } else {
                            let newNote = NoteModel(title: title, content: content, tags: Set(tags))
                            await viewModel.addNote(newNote, in: modelContext)
                        }

                        dismiss()
                    }
                }
                .disabled(title.isEmpty && content.isEmpty)
            }
        }
    }
}
