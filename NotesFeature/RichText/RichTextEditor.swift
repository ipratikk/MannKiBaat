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

    struct FormatAction: Equatable {
        let style: TextStyle
        let id = UUID()
        static func == (lhs: FormatAction, rhs: FormatAction) -> Bool { lhs.id == rhs.id }
    }

    enum TextStyle { case bold, italic, underline, bullet, checklist }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        weak var textView: UITextView?

        init(_ parent: RichTextEditor) { self.parent = parent }

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

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard text == "\n" else { return true }
            let fullText = textView.text as NSString
            let cursorLocation = range.location
            let lineRange = fullText.lineRange(for: NSRange(location: max(0, cursorLocation - 1), length: 0))
            let currentLine = fullText.substring(with: lineRange)
            let bullet = "\u{2022} "
            let checklist = "\u{2610} "
            var prefix: String? = nil
            if currentLine.hasPrefix(bullet) { prefix = bullet }
            else if currentLine.hasPrefix(checklist) { prefix = checklist }

            if let prefix {
                let trimmed = currentLine.trimmingCharacters(in: .newlines)
                if trimmed == prefix.trimmingCharacters(in: .whitespaces) {
                    textView.textStorage.replaceCharacters(in: NSRange(location: lineRange.location, length: prefix.count), with: NSAttributedString(string: ""))
                } else {
                    let attrs = textView.typingAttributes
                    let insertAttr = NSAttributedString(string: "\n" + prefix, attributes: attrs)
                    textView.textStorage.replaceCharacters(in: range, with: insertAttr)
                    let newLoc = range.location + insertAttr.length
                    DispatchQueue.main.async { textView.selectedRange = NSRange(location: newLoc, length: 0) }
                }
                textView.layoutManager.ensureLayout(for: textView.textContainer)
                DispatchQueue.main.async {
                    self.parent.attributedText = textView.attributedText
                    self.parent.selectedRange = textView.selectedRange
                }
                return false
            }
            return true
        }

        func insertPrefix(_ prefix: String, into textView: UITextView) {
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
                DispatchQueue.main.async { textView.selectedRange = NSRange(location: lineRange.location + newText.count, length: 0) }
            } else {
                let newText = prefix + lineContent + (hasNewline ? "\n" : "")
                textView.textStorage.replaceCharacters(in: lineRange, with: NSAttributedString(string: newText, attributes: attrs))
                DispatchQueue.main.async { textView.selectedRange = NSRange(location: lineRange.location + prefix.count + lineContent.count, length: 0) }
            }
            textView.layoutManager.ensureLayout(for: textView.textContainer)
            DispatchQueue.main.async {
                self.parent.attributedText = textView.attributedText
                self.parent.selectedRange = textView.selectedRange
            }
        }

        func applyStyle(_ style: RichTextEditor.TextStyle) {
            guard let textView = self.textView else { return }
            switch style {
            case .bold: toggleTrait(.traitBold, in: textView)
            case .italic: toggleTrait(.traitItalic, in: textView)
            case .underline: toggleUnderline(in: textView)
            case .bullet: insertPrefix("\u{2022} ", into: textView)
            case .checklist: insertPrefix("\u{2610} ", into: textView)
            }
            textView.layoutManager.ensureLayout(for: textView.textContainer)
            DispatchQueue.main.async {
                self.parent.attributedText = textView.attributedText
                self.parent.selectedRange = textView.selectedRange
            }
        }

        private func toggleTrait(_ trait: UIFontDescriptor.SymbolicTraits, in textView: UITextView) {
            let range = textView.selectedRange
            guard range.length > 0 else { return }
            textView.textStorage.beginEditing()
            textView.textStorage.enumerateAttribute(.font, in: range) { value, subRange, _ in
                guard let font = value as? UIFont else { return }
                var traits = font.fontDescriptor.symbolicTraits
                if traits.contains(trait) { traits.remove(trait) } else { traits.insert(trait) }
                if let descriptor = font.fontDescriptor.withSymbolicTraits(traits) {
                    textView.textStorage.addAttribute(.font, value: UIFont(descriptor: descriptor, size: font.pointSize), range: subRange)
                }
            }
            textView.textStorage.endEditing()
        }

        private func toggleUnderline(in textView: UITextView) {
            let range = textView.selectedRange
            guard range.length > 0 else { return }
            textView.textStorage.beginEditing()
            textView.textStorage.enumerateAttribute(.underlineStyle, in: range) { value, subRange, _ in
                let style = value as? Int ?? 0
                if style == 0 { textView.textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: subRange) }
                else { textView.textStorage.removeAttribute(.underlineStyle, range: subRange) }
            }
            textView.textStorage.endEditing()
        }
    }

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        context.coordinator.textView = tv
        tv.isEditable = true
        tv.isScrollEnabled = true
        tv.font = UIFont.systemFont(ofSize: 16)
        tv.attributedText = attributedText
        tv.selectedRange = selectedRange
        tv.keyboardDismissMode = .interactive
        tv.backgroundColor = .clear
        tv.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        context.coordinator.textView = uiView
        if uiView.attributedText != attributedText { uiView.attributedText = attributedText }
        if uiView.selectedRange != selectedRange { uiView.selectedRange = selectedRange }
        if isFocused.wrappedValue && !uiView.isFirstResponder { uiView.becomeFirstResponder() }
        else if !isFocused.wrappedValue && uiView.isFirstResponder { uiView.resignFirstResponder() }

        if let action = formatAction {
            DispatchQueue.main.async { [weak uiView] in
                guard uiView != nil else { return }
                context.coordinator.applyStyle(action.style)
                DispatchQueue.main.async { self.formatAction = nil }
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }
}
