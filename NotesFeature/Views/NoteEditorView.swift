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
                // Assuming you have a RichTextEditor that binds to NSAttributedString
                RichTextEditor(attributedText: $richText, isFocused: $isContentFocused)
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
                Button(action: insertBullet) { Image(systemName: "list.bullet") }
                Button(action: insertChecklist) { Image(systemName: "checklist") }
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

    // MARK: - Styling helpers (apply to the whole selection if selection isn't available)
    private func applyStyle(_ style: TextStyle) {
        let mutable = NSMutableAttributedString(attributedString: richText)
        let range = NSRange(location: 0, length: mutable.length)

        switch style {
        case .bold:
            toggleFontTrait(.traitBold, in: mutable, range: range)
        case .italic:
            toggleFontTrait(.traitItalic, in: mutable, range: range)
        case .underline:
            toggleUnderline(in: mutable, range: range)
        }

        richText = mutable
    }

    private func toggleFontTrait(_ trait: UIFontDescriptor.SymbolicTraits, in mutable: NSMutableAttributedString, range: NSRange) {
        #if canImport(UIKit)
        mutable.enumerateAttribute(.font, in: range) { value, subrange, _ in
            let font = (value as? UIFont) ?? UIFont.preferredFont(forTextStyle: .body)
            let currentTraits = font.fontDescriptor.symbolicTraits
            let hasTrait = currentTraits.contains(trait)

            let newTraitsRaw: UInt32 = {
                if hasTrait {
                    return currentTraits.rawValue & ~trait.rawValue
                } else {
                    return currentTraits.rawValue | trait.rawValue
                }
            }()

            let newTraits = UIFontDescriptor.SymbolicTraits(rawValue: newTraitsRaw)
            if let descriptor = font.fontDescriptor.withSymbolicTraits(newTraits) {
                let newFont = UIFont(descriptor: descriptor, size: font.pointSize)
                mutable.addAttribute(.font, value: newFont, range: subrange)
            }
        }
        #endif
    }

    private func toggleUnderline(in mutable: NSMutableAttributedString, range: NSRange) {
        mutable.enumerateAttribute(.underlineStyle, in: range) { value, subrange, _ in
            let current = (value as? Int) ?? 0
            if current == 0 {
                mutable.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: subrange)
            } else {
                mutable.removeAttribute(.underlineStyle, range: subrange)
            }
        }
    }

    private func insertBullet() {
        let mutable = NSMutableAttributedString(attributedString: richText)
        let bullet = NSAttributedString(string: mutable.length == 0 ? "• " : "\n• ")
        mutable.append(bullet)
        richText = mutable
    }

    private func insertChecklist() {
        let mutable = NSMutableAttributedString(attributedString: richText)
        let item = NSAttributedString(string: mutable.length == 0 ? "☐ " : "\n☐ ")
        mutable.append(item)
        richText = mutable
    }

    private enum TextStyle {
        case bold, italic, underline
    }
}
