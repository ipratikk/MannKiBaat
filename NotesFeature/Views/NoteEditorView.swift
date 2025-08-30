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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String
    @State private var content: String
    @State private var tagsText: String
    private var existingNote: NoteModel?
    
    public init(viewModel: NotesViewModel, note: NoteModel? = nil) {
        self.viewModel = viewModel
        self.existingNote = note
        _title = State(initialValue: note?.title ?? "")
        _content = State(initialValue: note?.content ?? "")
        _tagsText = State(initialValue: note?.tags.joined(separator: ", ") ?? "")
    }
    
    public var body: some View {
        Form {
            Section("Title") { TextField("Enter title", text: $title) }
            Section("Content") { TextEditor(text: $content).frame(minHeight: 100) }
            Section("Tags (comma separated)") {
                TextField("tag1, tag2, tag3", text: $tagsText)
            }
        }
        .navigationTitle(existingNote == nil ? "New Note" : "Edit Note")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save", action: saveNote)
                    .disabled(title.isEmpty && content.isEmpty)
            }
        }
    }
    
    private func saveNote() {
        Task {
            let tags = tagsText
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            if let note = existingNote {
                note.title = title
                note.content = content
                note.tags = Set(tags)
                await viewModel.updateNote(note, in: modelContext)
            } else {
                let note = NoteModel(title: title, content: content, tags: Set(tags))
                await viewModel.addNote(note, in: modelContext)
            }
            dismiss()
        }
    }
}
