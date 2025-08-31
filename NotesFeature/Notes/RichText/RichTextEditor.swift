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
    @Binding var formatAction: FormatAction?
    var onTextChange: ((NSAttributedString) -> Void)?

    struct FormatAction: Equatable {
        let style: TextStyle
        let id = UUID()
        static func == (lhs: FormatAction, rhs: FormatAction) -> Bool { lhs.id == rhs.id }
    }

    enum TextStyle {
        case bold, italic, underline
        case largeTitle, title1, title2, title3, headline, body, callout, subheadline, footnote, caption1, caption2
        case bullet, numberedList
        case strikethrough
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        weak var textView: UITextView?
        var lastKnownText: NSAttributedString?
        var isUpdatingFromParent = false

        init(_ parent: RichTextEditor) {
            self.parent = parent
            super.init()
        }

        func textViewDidChange(_ textView: UITextView) {
            guard !isUpdatingFromParent else { return }
            
            // Only notify parent if text actually changed
            if let lastText = lastKnownText, textView.attributedText.isEqual(to: lastText) {
                return
            }
            
            lastKnownText = textView.attributedText
            parent.onTextChange?(textView.attributedText)
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused.wrappedValue = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFocused.wrappedValue = false
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !isUpdatingFromParent else { return }
            
            // Update selection binding
            if textView.selectedRange.location != parent.selectedRange.location ||
               textView.selectedRange.length != parent.selectedRange.length {
                DispatchQueue.main.async {
                    self.parent.selectedRange = textView.selectedRange
                }
            }
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard text == "\n" else { return true }
            
            let fullText = textView.text as NSString
            let lineRange = fullText.lineRange(for: NSRange(location: max(0, range.location - 1), length: 0))
            let currentLine = fullText.substring(with: lineRange)
            
            // Handle lists
            let bullet = "• "
            let numberedPattern = #"^\d+\.\s"#
            let regex = try? NSRegularExpression(pattern: numberedPattern)
            
            if currentLine.hasPrefix(bullet) {
                let trimmed = currentLine.trimmingCharacters(in: .newlines)
                if trimmed == bullet.trimmingCharacters(in: .whitespaces) {
                    // Remove empty bullet
                    textView.textStorage.replaceCharacters(in: NSRange(location: lineRange.location, length: bullet.count), with: NSAttributedString(string: ""))
                    return false
                } else {
                    // Continue bullet list
                    let attrs = textView.typingAttributes
                    let insertAttr = NSAttributedString(string: "\n" + bullet, attributes: attrs)
                    textView.textStorage.replaceCharacters(in: range, with: insertAttr)
                    textView.selectedRange = NSRange(location: range.location + insertAttr.length, length: 0)
                    return false
                }
            } else if let match = regex?.firstMatch(in: currentLine, range: NSRange(location: 0, length: currentLine.count)) {
                let matchedPrefix = (currentLine as NSString).substring(with: match.range)
                let trimmed = currentLine.trimmingCharacters(in: .newlines)
                
                if trimmed == matchedPrefix.trimmingCharacters(in: .whitespaces) {
                    // Remove empty number
                    textView.textStorage.replaceCharacters(in: NSRange(location: lineRange.location, length: matchedPrefix.count), with: NSAttributedString(string: ""))
                    return false
                } else {
                    // Continue numbered list
                    let components = matchedPrefix.components(separatedBy: ".")
                    if let numberStr = components.first, let number = Int(numberStr) {
                        let nextPrefix = "\(number + 1). "
                        let attrs = textView.typingAttributes
                        let insertAttr = NSAttributedString(string: "\n" + nextPrefix, attributes: attrs)
                        textView.textStorage.replaceCharacters(in: range, with: insertAttr)
                        textView.selectedRange = NSRange(location: range.location + insertAttr.length, length: 0)
                        return false
                    }
                }
            }
            
            return true
        }

        func applyStyle(_ style: RichTextEditor.TextStyle) {
            guard let textView = self.textView else { return }
            
            switch style {
            case .bold: toggleTrait(.traitBold, in: textView)
            case .italic: toggleTrait(.traitItalic, in: textView)
            case .underline: toggleUnderline(in: textView)
            case .strikethrough: toggleStrikethrough(in: textView)
            case .bullet: insertPrefix("• ", into: textView)
            case .numberedList: insertNumberedList(into: textView)
            case .largeTitle: applyFontStyle(textStyle: .largeTitle, in: textView)
            case .title1: applyFontStyle(textStyle: .title1, in: textView)
            case .title2: applyFontStyle(textStyle: .title2, in: textView)
            case .title3: applyFontStyle(textStyle: .title3, in: textView)
            case .headline: applyFontStyle(textStyle: .headline, in: textView)
            case .body: applyFontStyle(textStyle: .body, in: textView)
            case .callout: applyFontStyle(textStyle: .callout, in: textView)
            case .subheadline: applyFontStyle(textStyle: .subheadline, in: textView)
            case .footnote: applyFontStyle(textStyle: .footnote, in: textView)
            case .caption1: applyFontStyle(textStyle: .caption1, in: textView)
            case .caption2: applyFontStyle(textStyle: .caption2, in: textView)
            }
        }

        private func insertPrefix(_ prefix: String, into textView: UITextView) {
            let fullText = textView.text as NSString
            let cursorLocation = textView.selectedRange.location
            let lineRange = fullText.lineRange(for: NSRange(location: max(0, cursorLocation), length: 0))
            let currentLine = fullText.substring(with: lineRange)
            let lineContent = currentLine.trimmingCharacters(in: .newlines)
            let hasNewline = currentLine.hasSuffix("\n")
            let attrs = lineRange.length > 0 ? textView.textStorage.attributes(at: lineRange.location, effectiveRange: nil) : textView.typingAttributes

            if lineContent.hasPrefix(prefix.trimmingCharacters(in: .whitespaces)) {
                let newText = String(lineContent.dropFirst(prefix.count)) + (hasNewline ? "\n" : "")
                textView.textStorage.replaceCharacters(in: lineRange, with: NSAttributedString(string: newText, attributes: attrs))
                textView.selectedRange = NSRange(location: lineRange.location + newText.count - (hasNewline ? 1 : 0), length: 0)
            } else {
                let newText = prefix + lineContent + (hasNewline ? "\n" : "")
                textView.textStorage.replaceCharacters(in: lineRange, with: NSAttributedString(string: newText, attributes: attrs))
                textView.selectedRange = NSRange(location: lineRange.location + prefix.count + lineContent.count - (hasNewline ? 1 : 0), length: 0)
            }
        }

        private func insertNumberedList(into textView: UITextView) {
            let fullText = textView.text as NSString
            let cursorLocation = textView.selectedRange.location
            let lineRange = fullText.lineRange(for: NSRange(location: max(0, cursorLocation), length: 0))
            let currentLine = fullText.substring(with: lineRange)
            let lineContent = currentLine.trimmingCharacters(in: .newlines)
            let hasNewline = currentLine.hasSuffix("\n")
            let attrs = lineRange.length > 0 ? textView.textStorage.attributes(at: lineRange.location, effectiveRange: nil) : textView.typingAttributes

            let numberedPattern = #"^\d+\.\s"#
            let regex = try? NSRegularExpression(pattern: numberedPattern)
            
            if let match = regex?.firstMatch(in: lineContent, range: NSRange(location: 0, length: lineContent.count)) {
                // Remove numbering
                let withoutNumber = String(lineContent.dropFirst(match.range.length))
                let newText = withoutNumber + (hasNewline ? "\n" : "")
                textView.textStorage.replaceCharacters(in: lineRange, with: NSAttributedString(string: newText, attributes: attrs))
                textView.selectedRange = NSRange(location: lineRange.location + withoutNumber.count - (hasNewline ? 1 : 0), length: 0)
            } else {
                // Add numbering (start with 1.)
                let newText = "1. " + lineContent + (hasNewline ? "\n" : "")
                textView.textStorage.replaceCharacters(in: lineRange, with: NSAttributedString(string: newText, attributes: attrs))
                textView.selectedRange = NSRange(location: lineRange.location + 3 + lineContent.count - (hasNewline ? 1 : 0), length: 0)
            }
        }

        private func applyFontStyle(textStyle: UIFont.TextStyle, in textView: UITextView) {
            let range = textView.selectedRange
            let newFont = UIFont.preferredFont(forTextStyle: textStyle)
            
            if range.length > 0 {
                // Apply to selection
                textView.textStorage.addAttribute(.font, value: newFont, range: range)
            } else {
                // Apply to typing attributes
                textView.typingAttributes[.font] = newFont
            }
        }

        private func toggleTrait(_ trait: UIFontDescriptor.SymbolicTraits, in textView: UITextView) {
            let range = textView.selectedRange
            
            if range.length > 0 {
                // Apply to selection
                textView.textStorage.beginEditing()
                textView.textStorage.enumerateAttribute(.font, in: range) { value, subRange, _ in
                    guard let font = value as? UIFont else { return }
                    var traits = font.fontDescriptor.symbolicTraits
                    if traits.contains(trait) {
                        traits.remove(trait)
                    } else {
                        traits.insert(trait)
                    }
                    if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                        let newFont = UIFont(descriptor: descriptor, size: font.pointSize)
                        textView.textStorage.addAttribute(.font, value: newFont, range: subRange)
                    }
                }
                textView.textStorage.endEditing()
            } else {
                // Apply to typing attributes
                let currentFont = textView.typingAttributes[.font] as? UIFont ?? UIFont.preferredFont(forTextStyle: .body)
                var traits = currentFont.fontDescriptor.symbolicTraits
                if traits.contains(trait) {
                    traits.remove(trait)
                } else {
                    traits.insert(trait)
                }
                if let descriptor = currentFont.fontDescriptor.withSymbolicTraits(traits) {
                    textView.typingAttributes[.font] = UIFont(descriptor: descriptor, size: currentFont.pointSize)
                }
            }
        }

        private func toggleUnderline(in textView: UITextView) {
            let range = textView.selectedRange
            
            if range.length > 0 {
                textView.textStorage.beginEditing()
                textView.textStorage.enumerateAttribute(.underlineStyle, in: range) { value, subRange, _ in
                    let style = value as? Int ?? 0
                    if style == 0 {
                        textView.textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: subRange)
                    } else {
                        textView.textStorage.removeAttribute(.underlineStyle, range: subRange)
                    }
                }
                textView.textStorage.endEditing()
            } else {
                let currentStyle = textView.typingAttributes[.underlineStyle] as? Int ?? 0
                if currentStyle == 0 {
                    textView.typingAttributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
                } else {
                    textView.typingAttributes.removeValue(forKey: .underlineStyle)
                }
            }
        }

        private func toggleStrikethrough(in textView: UITextView) {
            let range = textView.selectedRange
            
            if range.length > 0 {
                textView.textStorage.beginEditing()
                textView.textStorage.enumerateAttribute(.strikethroughStyle, in: range) { value, subRange, _ in
                    let style = value as? Int ?? 0
                    if style == 0 {
                        textView.textStorage.addAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: subRange)
                    } else {
                        textView.textStorage.removeAttribute(.strikethroughStyle, range: subRange)
                    }
                }
                textView.textStorage.endEditing()
            } else {
                let currentStyle = textView.typingAttributes[.strikethroughStyle] as? Int ?? 0
                if currentStyle == 0 {
                    textView.typingAttributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
                } else {
                    textView.typingAttributes.removeValue(forKey: .strikethroughStyle)
                }
            }
        }
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        context.coordinator.textView = textView
        
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.keyboardDismissMode = .interactive
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        textView.contentInsetAdjustmentBehavior = .automatic
        
        // Apple Notes style settings
        textView.autocorrectionType = .yes
        textView.autocapitalizationType = .sentences
        textView.spellCheckingType = .yes
        textView.smartQuotesType = .yes
        textView.smartDashesType = .yes
        textView.smartInsertDeleteType = .yes
        
        // Set initial content
        textView.attributedText = attributedText
        textView.selectedRange = selectedRange
        context.coordinator.lastKnownText = attributedText
        
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.textView = textView
        
        // Handle focus changes
        if isFocused.wrappedValue && !textView.isFirstResponder {
            textView.becomeFirstResponder()
        } else if !isFocused.wrappedValue && textView.isFirstResponder {
            textView.resignFirstResponder()
        }

        // Handle format actions
        if let action = formatAction {
            context.coordinator.applyStyle(action.style)
            DispatchQueue.main.async {
                self.formatAction = nil
            }
        }

        // Update text only if it's different and not from user typing
        if !textView.attributedText.isEqual(to: attributedText) {
            context.coordinator.isUpdatingFromParent = true
            let oldSelection = textView.selectedRange
            textView.attributedText = attributedText
            
            // Restore selection if valid
            let maxLocation = attributedText.length
            let newLocation = min(selectedRange.location, maxLocation)
            let maxLength = maxLocation - newLocation
            let newLength = min(selectedRange.length, max(0, maxLength))
            textView.selectedRange = NSRange(location: newLocation, length: newLength)
            
            context.coordinator.lastKnownText = attributedText
            
            DispatchQueue.main.async {
                context.coordinator.isUpdatingFromParent = false
            }
        } else if textView.selectedRange != selectedRange {
            textView.selectedRange = selectedRange
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
