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

    @State private var tagsText: String
    @FocusState private var isContentFocused: Bool
    @State private var richText: NSAttributedString
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    
    @State private var formatAction: RichTextEditor.FormatAction?

    public init(note: NoteModel, viewModel: NotesViewModel) {
        self.note = note
        self.viewModel = viewModel
        _tagsText = State(initialValue: note.tags.joined(separator: ", "))
        _richText = State(initialValue: note.attributedContent)
    }

    public var body: some View {
        Form {
            Section("Title") {
                TextField("Title", text: $note.title)
                    .disableAutocorrection(true)
            }

            Section("Content") {
                RichTextEditor(
                    attributedText: $richText,
                    selectedRange: $selectedRange,
                    isFocused: $isContentFocused,
                    formatAction: $formatAction
                )
                .frame(minHeight: 220)
                .focused($isContentFocused)
            }

            Section("Tags (comma separated)") {
                TextField("tag1, tag2", text: $tagsText)
                    .onChange(of: tagsText) { newValue in
                        let newTags = newValue
                            .split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        note.tags = Set(newTags)
                    }
            }
        }
        .navigationTitle("Edit Note")
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 16) {
                Button(action: { applyStyle(.bold) }) { Image(systemName: "bold") }
                Button(action: { applyStyle(.italic) }) { Image(systemName: "italic") }
                Button(action: { applyStyle(.underline) }) { Image(systemName: "underline") }
                Button(action: { applyStyle(.bullet) }) { Image(systemName: "list.bullet") }
                Button(action: { applyStyle(.checklist) }) { Image(systemName: "checklist") }
            }
            .padding(.vertical, 8)
            .padding(.horizontal)
            .background(.ultraThinMaterial)
            .cornerRadius(12)
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") { saveNote() }
            }
        }
    }

    private func saveNote() {
        Task {
            note.attributedContent = richText
            await viewModel.updateNote(note, in: modelContext)
        }
    }

    private func applyStyle(_ style: RichTextEditor.TextStyle) {
        DispatchQueue.main.async {
            formatAction = RichTextEditor.FormatAction(style: style)
        }
    }
}
