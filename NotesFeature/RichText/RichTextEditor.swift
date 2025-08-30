//
//  RichTextEditor.swift
//  MannKiBaat
//

import SwiftUI
import UIKit

struct RichTextEditor: UIViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var selectedRange: NSRange
    var isFocused: FocusState<Bool>.Binding
    
    // Action trigger for formatting
    @Binding var formatAction: FormatAction?
    
    struct FormatAction: Equatable {
        let style: TextStyle
        let id = UUID()
        
        static func == (lhs: FormatAction, rhs: FormatAction) -> Bool {
            lhs.id == rhs.id
        }
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        weak var textView: UITextView?

        init(_ parent: RichTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.attributedText = textView.attributedText
            parent.selectedRange = textView.selectedRange
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused.wrappedValue = true
            parent.selectedRange = textView.selectedRange
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFocused.wrappedValue = false
            parent.selectedRange = textView.selectedRange
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
        }

        // Format current line with prefix (bullet / checkbox) and move cursor to end of line
        func insertPrefix(_ prefix: String, into textView: UITextView) {
            let fullText = textView.text as NSString
            let cursorLocation = textView.selectedRange.location
            
            print("insertPrefix called with prefix: '\(prefix)', cursor at: \(cursorLocation), text length: \(fullText.length)")
            
            // Handle empty text case
            if fullText.length == 0 {
                let attrs = textView.typingAttributes
                let newAttrString = NSAttributedString(string: prefix, attributes: attrs)
                textView.textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: newAttrString)
                
                DispatchQueue.main.async {
                    textView.selectedRange = NSRange(location: prefix.count, length: 0)
                    self.parent.attributedText = textView.attributedText
                    self.parent.selectedRange = textView.selectedRange
                }
                return
            }
            
            // Find the current line range (not paragraph)
            let safeLocation = min(max(cursorLocation, 0), fullText.length - 1)
            let lineRange = fullText.lineRange(for: NSRange(location: safeLocation, length: 0))
            let currentLine = fullText.substring(with: lineRange)
            
            print("Current line: '\(currentLine)', line range: \(lineRange)")
            
            // Get line content without newline
            let lineContent = currentLine.trimmingCharacters(in: .newlines)
            let hasNewline = currentLine.hasSuffix("\n")
            
            // Check if line already has this prefix
            let prefixTrimmed = prefix.trimmingCharacters(in: .whitespaces)
            if lineContent.hasPrefix(prefixTrimmed) {
                // Remove the prefix
                let withoutPrefix = String(lineContent.dropFirst(prefix.count))
                let newLineText = withoutPrefix + (hasNewline ? "\n" : "")
                
                let attrs = textView.textStorage.attributes(at: lineRange.location, effectiveRange: nil)
                let newAttrString = NSAttributedString(string: newLineText, attributes: attrs)
                
                textView.textStorage.replaceCharacters(in: lineRange, with: newAttrString)
                
                let newCursorLocation = lineRange.location + withoutPrefix.count
                
                DispatchQueue.main.async {
                    textView.selectedRange = NSRange(location: newCursorLocation, length: 0)
                    self.parent.attributedText = textView.attributedText
                    self.parent.selectedRange = textView.selectedRange
                }
            } else {
                // Add the prefix at the beginning of the line
                let newLineText = prefix + lineContent + (hasNewline ? "\n" : "")
                
                let attrs = textView.textStorage.attributes(at: lineRange.location, effectiveRange: nil)
                let newAttrString = NSAttributedString(string: newLineText, attributes: attrs)
                
                textView.textStorage.replaceCharacters(in: lineRange, with: newAttrString)
                
                // Move cursor to end of line content (before newline)
                let newCursorLocation = lineRange.location + prefix.count + lineContent.count
                
                DispatchQueue.main.async {
                    textView.selectedRange = NSRange(location: newCursorLocation, length: 0)
                    self.parent.attributedText = textView.attributedText
                    self.parent.selectedRange = textView.selectedRange
                }
            }
        }

        // Handle Return key for continuing / ending bullet/checklist lines
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // Only intercept Return
            guard text == "\n" else { return true }

            let full = textView.text as NSString
            // If there's no character before cursor, probeLocation would be 0
            let cursorLocation = range.location
            let probeLocation = max(cursorLocation - 1, 0)
            let lineRange = full.lineRange(for: NSRange(location: probeLocation, length: 0))
            let currentLine = full.substring(with: lineRange)

            let bullet = "• "
            let checklist = "☐ "
            var prefix: String? = nil
            if currentLine.hasPrefix(bullet) { prefix = bullet }
            else if currentLine.hasPrefix(checklist) { prefix = checklist }

            if let prefix = prefix {
                // Trim only newline characters for emptiness check
                let trimmed = currentLine.trimmingCharacters(in: .newlines)

                if trimmed == prefix.trimmingCharacters(in: .whitespaces) {
                    // Line contains only the prefix — remove it instead of inserting newline
                    let prefixRange = NSRange(location: lineRange.location, length: prefix.count)
                    textView.textStorage.replaceCharacters(in: prefixRange, with: NSAttributedString(string: ""))
                    textView.layoutManager.ensureLayout(for: textView.textContainer)

                    DispatchQueue.main.async {
                        textView.selectedRange = NSRange(location: lineRange.location, length: 0)
                        self.parent.attributedText = textView.attributedText
                        self.parent.selectedRange = textView.selectedRange
                    }

                    return false
                } else {
                    // Continue list: insert newline + prefix, move caret after prefix
                    let attrs = (textView.typingAttributes as? [NSAttributedString.Key: Any]) ?? [:]
                    let insertAttr = NSAttributedString(string: "\n" + prefix, attributes: attrs)

                    textView.textStorage.replaceCharacters(in: range, with: insertAttr)
                    textView.layoutManager.ensureLayout(for: textView.textContainer)
                    let newLoc = range.location + insertAttr.length

                    DispatchQueue.main.async {
                        textView.selectedRange = NSRange(location: newLoc, length: 0)
                        textView.scrollRangeToVisible(textView.selectedRange)
                        self.parent.attributedText = textView.attributedText
                        self.parent.selectedRange = textView.selectedRange
                    }

                    return false
                }
            }

            return true
        }
        
        // MARK: - Apply Formatting Styles
        
        func applyStyle(_ style: RichTextEditor.TextStyle) {
            guard let textView = self.textView else {
                print("No textView available for style: \(style)")
                return
            }
            
            print("Applying style: \(style)")
            
            switch style {
            case .bold:
                let selectedRange = textView.selectedRange
                guard selectedRange.length > 0 else { return }
                toggleTrait(.traitBold, in: textView, range: selectedRange)
                parent.attributedText = textView.attributedText
                parent.selectedRange = textView.selectedRange
            case .italic:
                let selectedRange = textView.selectedRange
                guard selectedRange.length > 0 else { return }
                toggleTrait(.traitItalic, in: textView, range: selectedRange)
                parent.attributedText = textView.attributedText
                parent.selectedRange = textView.selectedRange
            case .underline:
                let selectedRange = textView.selectedRange
                guard selectedRange.length > 0 else { return }
                toggleUnderline(in: textView, range: selectedRange)
                parent.attributedText = textView.attributedText
                parent.selectedRange = textView.selectedRange
            case .bullet:
                insertPrefix("• ", into: textView)
            case .checklist:
                insertPrefix("☐ ", into: textView)
            }
        }
        
        private func toggleTrait(_ trait: UIFontDescriptor.SymbolicTraits, in textView: UITextView, range: NSRange) {
            textView.textStorage.beginEditing()
            textView.textStorage.enumerateAttribute(.font, in: range, options: []) { value, range, _ in
                if let font = value as? UIFont {
                    var traits = font.fontDescriptor.symbolicTraits
                    if traits.contains(trait) {
                        traits.remove(trait)
                    } else {
                        traits.insert(trait)
                    }
                    if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                        let newFont = UIFont(descriptor: descriptor, size: font.pointSize)
                        textView.textStorage.addAttribute(.font, value: newFont, range: range)
                    }
                }
            }
            textView.textStorage.endEditing()
        }
        
        private func toggleUnderline(in textView: UITextView, range: NSRange) {
            textView.textStorage.beginEditing()
            textView.textStorage.enumerateAttribute(.underlineStyle, in: range, options: []) { value, range, _ in
                let currentStyle = value as? Int ?? 0
                if currentStyle == 0 {
                    textView.textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
                } else {
                    textView.textStorage.removeAttribute(.underlineStyle, range: range)
                }
            }
            textView.textStorage.endEditing()
        }
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        context.coordinator.textView = textView
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.attributedText = attributedText
        textView.selectedRange = selectedRange
        textView.keyboardDismissMode = .interactive
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Always ensure coordinator has text view reference
        context.coordinator.textView = uiView
        
        // Only update if different to avoid stomping selection
        if uiView.attributedText != attributedText {
            uiView.attributedText = attributedText
        }

        if uiView.selectedRange != selectedRange {
            uiView.selectedRange = selectedRange
        }

        if isFocused.wrappedValue && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFocused.wrappedValue && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
        
        // Handle format action after UI updates
        if let action = formatAction {
            print("Processing format action: \(action.style)")
            context.coordinator.applyStyle(action.style)
            // Reset the action
            formatAction = nil
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

extension RichTextEditor {
    enum TextStyle {
        case bold
        case italic
        case underline
        case bullet
        case checklist
    }
}
