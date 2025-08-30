//
//  NoteEditorView.swift
//  MannKiBaat
//

import SwiftUI
import SwiftData
import SharedModels

#if canImport(UIKit)
import UIKit
#endif

@MainActor
public struct NoteEditorView: View {
    @ObservedObject public var viewModel: NotesViewModel
    @Bindable public var note: NoteModel
    @Environment(\.modelContext) private var modelContext

    @State private var tagsText: String
    @FocusState private var isContentFocused: Bool
    @State private var richText: NSAttributedString
    @State private var selectedRange: NSRange = NSRange(location: 0, length: 0)
    
    // Use binding for format actions
    @State private var formatAction: RichTextEditor.FormatAction?

    public init(note: NoteModel, viewModel: NotesViewModel) {
        self.note = note
        self.viewModel = viewModel
        _tagsText = State(initialValue: note.tags.joined(separator: ", "))
        // initialize richText from note.attributedContent if available, else empty
        _richText = State(initialValue: note.attributedContent ?? NSAttributedString(string: ""))
    }

    public var body: some View {
        Form {
            Section("Title") {
                TextField("Title", text: $note.title)
                    .disableAutocorrection(true)
            }

            Section("Content") {
                // Use the RichTextEditor with format action binding
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
                Button("Save") {
                    saveNote()
                }
            }
        }
    }

    // MARK: - Save
    private func saveNote() {
        Task {
            // Persist the rich text directly into the model's `attributedContent` property
            note.attributedContent = richText

            await viewModel.updateNote(note, in: modelContext)
        }
    }

    // MARK: - Styling helpers
    private func applyStyle(_ style: RichTextEditor.TextStyle) {
        // All formatting is handled by the RichTextEditor through formatAction
        formatAction = RichTextEditor.FormatAction(style: style)
    }
}
