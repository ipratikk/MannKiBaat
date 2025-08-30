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
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: RichTextEditor
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.attributedText = textView.attributedText
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused.wrappedValue = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFocused.wrappedValue = false
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.selectedRange = textView.selectedRange
        }

        // Handle bullet/checklist continuation and removal on return
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            // Only care about return key
            guard text == "\n" else { return true }
            // Find the current line
            let textNSString = textView.text as NSString
            let fullText = textNSString as String
            // Find the range of the current line
            let cursorLocation = range.location
            let lineRange = (fullText as NSString).lineRange(for: NSRange(location: cursorLocation, length: 0))
            let currentLine = (fullText as NSString).substring(with: lineRange)
            let bullet = "• "
            let checklist = "☐ "
            var prefix: String? = nil
            if currentLine.hasPrefix(bullet) {
                prefix = bullet
            } else if currentLine.hasPrefix(checklist) {
                prefix = checklist
            }
            if let prefix = prefix {
                // Get the content after the prefix (trim trailing newline)
                let trimmed = currentLine.trimmingCharacters(in: .newlines)
                if trimmed == prefix {
                    // The line only contains the prefix, so pressing return removes the prefix (ends the list)
                    // Remove the prefix from this line
                    let prefixRange = NSRange(location: lineRange.location, length: prefix.count)
                    let textStorage = textView.textStorage
                    textStorage.replaceCharacters(in: prefixRange, with: "")
                    // Move cursor to start of line
                    let newLoc = lineRange.location
                    textView.selectedRange = NSRange(location: newLoc, length: 0)
                    // Sync back
                    parent.attributedText = textView.attributedText
                    parent.selectedRange = textView.selectedRange
                    return false
                } else {
                    // Continue the list: insert newline + prefix
                    let insertString = "\n" + prefix
                    let textStorage = textView.textStorage
                    textStorage.replaceCharacters(in: range, with: insertString)
                    // Move cursor after the inserted prefix
                    let newLoc = range.location + insertString.count
                    textView.selectedRange = NSRange(location: newLoc, length: 0)
                    // Sync back
                    parent.attributedText = textView.attributedText
                    parent.selectedRange = textView.selectedRange
                    return false
                }
            }
            // Not a bullet or checklist line: normal return
            return true
        }
    }
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isScrollEnabled = true
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.attributedText = attributedText
        textView.selectedRange = selectedRange
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
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
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
