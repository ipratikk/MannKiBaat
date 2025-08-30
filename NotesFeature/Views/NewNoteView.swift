//
//  NewNoteView.swift
//  MannKiBaat
//
//  Created by Pratik Goel on 30/08/25.
//

import SwiftUI
import SharedModels

public struct NewNoteView: View {
    @ObservedObject var viewModel: NotesViewModel
    @Environment(\.dismiss) private var dismiss

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
                    TextField("Enter note title", text: $title)
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
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            let tagsSet = Set(
                                tagsText
                                    .split(separator: ",")
                                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                    .filter { !$0.isEmpty }
                            )

                            let note = Note(id: UUID(), title: title, content: content, tags: tagsSet)
                            await viewModel.addNote(note)
                            dismiss()
                        }
                    }
                    .disabled(title.isEmpty && content.isEmpty)
                }
            }
        }
    }
}
