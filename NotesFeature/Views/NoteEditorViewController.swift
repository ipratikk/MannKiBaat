//
//  NoteEditorViewController.swift
//  MannKiBaat
//

import UIKit
import SwiftUI
import SwiftData
import SharedModels
import Combine

class NoteEditorViewController: UIViewController, UITextViewDelegate {

    // MARK: - Properties
    var note: NoteModel
    var viewModel: NotesViewModel
    var modelContext: ModelContext
    var onDismiss: (() -> Void)?
    var onEditingChanged: ((Bool) -> Void)?
    private var isNewNote: Bool
    
    private lazy var textView: UITextView = {
        let tv = UITextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.delegate = self
        tv.isEditable = true
        tv.isScrollEnabled = true
        tv.font = UIFont.preferredFont(forTextStyle: .body)
        tv.backgroundColor = .systemBackground
        tv.textContainerInset = UIEdgeInsets(top: 20, left: 16, bottom: 20, right: 16)
        tv.keyboardDismissMode = .interactive
        tv.autocorrectionType = .yes
        tv.autocapitalizationType = .sentences
        tv.spellCheckingType = .yes
        tv.smartQuotesType = .yes
        tv.smartDashesType = .yes
        tv.smartInsertDeleteType = .yes
        tv.layer.cornerRadius = 12
        tv.clipsToBounds = true
        return tv
    }()

    private lazy var toolbarStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.distribution = .fill
        return stack
    }()

    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.alwaysBounceHorizontal = true
        return scroll
    }()

    private lazy var toolbarContainer: UIView = {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: container.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        return container
    }()

    private var toolbarBottomConstraint: NSLayoutConstraint!
    private var textViewBottomConstraint: NSLayoutConstraint!

    // Toolbar buttons
    private var boldButton: UIButton!
    private var italicButton: UIButton!
    private var underlineButton: UIButton!
    private var strikethroughButton: UIButton!
    private var listButton: UIButton!
    private var styleMenuButton: UIButton!

    // MARK: - Init
    init(note: NoteModel, viewModel: NotesViewModel, modelContext: ModelContext, isNewNote: Bool = false) {
        self.note = note
        self.viewModel = viewModel
        self.modelContext = modelContext
        self.isNewNote = isNewNote
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupToolbar()
        setupKeyboardObservers()
        loadNoteContent()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if textView.attributedText.string.isEmpty {
            textView.becomeFirstResponder()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveNote()
        onDismiss?()
        isEditing = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI Setup
    private func setupUI() {
        title = "Note"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonTapped))

        view.addSubview(textView)
        view.addSubview(toolbarContainer)
        toolbarContainer.addSubview(scrollView)
        scrollView.addSubview(toolbarStackView)

        let toolbarHeight: CGFloat = 50
        toolbarBottomConstraint = toolbarContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        // textViewBottomConstraint should be between textView.bottomAnchor and toolbarContainer.topAnchor
        textViewBottomConstraint = textView.bottomAnchor.constraint(equalTo: toolbarContainer.topAnchor)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textViewBottomConstraint,

            toolbarContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbarContainer.heightAnchor.constraint(equalToConstant: toolbarHeight),
            toolbarBottomConstraint,

            scrollView.topAnchor.constraint(equalTo: toolbarContainer.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: toolbarContainer.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: toolbarContainer.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: toolbarContainer.bottomAnchor),

            toolbarStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            toolbarStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            toolbarStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            toolbarStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])
    }

    // MARK: - Toolbar Setup
    private func setupToolbar() {
        styleMenuButton = createCircularToolbarButton(icon: "textformat.size", action: nil, isMenu: true)
        styleMenuButton.menu = textStyleMenu()
        toolbarStackView.addArrangedSubview(styleMenuButton)
        toolbarStackView.addArrangedSubview(createDivider())

        boldButton = createCircularToolbarButton(icon: "bold", action: #selector(toggleBold))
        italicButton = createCircularToolbarButton(icon: "italic", action: #selector(toggleItalic))
        underlineButton = createCircularToolbarButton(icon: "underline", action: #selector(toggleUnderlineFormatting))
        strikethroughButton = createCircularToolbarButton(icon: "strikethrough", action: #selector(toggleStrikethrough))
        toolbarStackView.addArrangedSubview(boldButton)
        toolbarStackView.addArrangedSubview(italicButton)
        toolbarStackView.addArrangedSubview(underlineButton)
        toolbarStackView.addArrangedSubview(strikethroughButton)
        toolbarStackView.addArrangedSubview(createDivider())

        listButton = createCircularToolbarButton(icon: "list.bullet", action: nil, isMenu: true)
        listButton.menu = listMenu()
        toolbarStackView.addArrangedSubview(listButton)
    }

    // MARK: - Keyboard Handling
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }
    
    func endEditing() {
        textView.resignFirstResponder()
        onEditingChanged?(false)
    }

    // MARK: - Load and Save
    private func loadNoteContent() {
        textView.attributedText = isNewNote ? NSAttributedString(string: "") : note.attributedContent
    }
    
    func removeNote() {
        Task { @MainActor in
            await viewModel.removeNote(note, in: modelContext)
            // Dismiss the view controller safely
            if let nav = self.navigationController {
                nav.popViewController(animated: true)
            } else {
                self.dismiss(animated: true)
            }
        }
    }

    private func saveNote() {
        let attributed = textView.attributedText ?? NSAttributedString(string: "")
        let fullString = attributed.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !fullString.isEmpty else {
            if !isNewNote {
                Task { @MainActor in
                    await viewModel.removeNote(note, in: modelContext)
                }
            }
            return
        }
        let title = fullString.components(separatedBy: "\n").first ?? fullString
        if isNewNote {
            let newNote = NoteModel(title: title, richTextData: attributed.archivedData())
            Task { @MainActor in
                await viewModel.addNote(newNote, in: modelContext)
            }
            self.note = newNote
            self.isNewNote = false
        } else {
            note.title = title
            note.attributedContent = attributed
            Task { @MainActor in
                await viewModel.updateNote(note, in: modelContext)
            }
        }
    }

    // MARK: - Actions
    @objc func doneButtonTapped() { saveNote(); dismiss(animated: true) }
    @objc private func toggleBold() { toggleTrait(.traitBold) }
    @objc private func toggleItalic() { toggleTrait(.traitItalic) }
    @objc private func toggleUnderlineFormatting() { toggleAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue) }
    @objc private func toggleStrikethrough() { toggleAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue) }

    // MARK: - Formatting Helpers
    private func toggleTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
        guard let selectedRange = textView.selectedTextRange else { return }
        let start = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
        let length = textView.offset(from: selectedRange.start, to: selectedRange.end)
        if length > 0 {
            let nsRange = safeRange(NSRange(location: start, length: length), for: textView.attributedText)
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            attrString.enumerateAttribute(.font, in: nsRange, options: []) { value, range, _ in
                let safeR = safeRange(range, for: attrString)
                let currentFont = value as? UIFont ?? UIFont.systemFont(ofSize: 16)
                var traitsSet = currentFont.fontDescriptor.symbolicTraits
                if traitsSet.contains(trait) { traitsSet.remove(trait) } else { traitsSet.insert(trait) }
                if let descriptor = currentFont.fontDescriptor.withSymbolicTraits(traitsSet) {
                    attrString.addAttribute(.font, value: UIFont(descriptor: descriptor, size: currentFont.pointSize), range: safeR)
                }
            }
            textView.attributedText = attrString
            textView.selectedRange = nsRange
        } else {
            // Toggle trait in typingAttributes (for running style)
            var typingAttrs = textView.typingAttributes
            let currentFont = (typingAttrs[.font] as? UIFont) ?? UIFont.systemFont(ofSize: 16)
            var traitsSet = currentFont.fontDescriptor.symbolicTraits
            if traitsSet.contains(trait) { traitsSet.remove(trait) } else { traitsSet.insert(trait) }
            if let descriptor = currentFont.fontDescriptor.withSymbolicTraits(traitsSet) {
                let newFont = UIFont(descriptor: descriptor, size: currentFont.pointSize)
                typingAttrs[.font] = newFont
                // Ensure underline/strikethrough states are preserved in typingAttributes
                textView.typingAttributes = typingAttrs
            }
        }
        updateToolbarButtonStates()
    }

    private func toggleAttribute(_ attribute: NSAttributedString.Key, value: Any) {
        guard let selectedRange = textView.selectedTextRange else { return }
        let start = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
        let length = textView.offset(from: selectedRange.start, to: selectedRange.end)
        if length > 0 {
            let nsRange = safeRange(NSRange(location: start, length: length), for: textView.attributedText)
            let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
            attrString.enumerateAttributes(in: nsRange, options: []) { attrs, range, _ in
                var newAttrs = attrs
                let currentValue = attrs[attribute]
                let shouldRemove: Bool
                if let intValue = value as? Int, let currentInt = currentValue as? Int {
                    shouldRemove = currentInt == intValue
                } else if let current = currentValue, "\(current)" == "\(value)" {
                    shouldRemove = true
                } else {
                    shouldRemove = false
                }
                newAttrs[attribute] = shouldRemove ? 0 : value
                if newAttrs[.font] == nil { newAttrs[.font] = textView.font ?? UIFont.systemFont(ofSize: 16) }
                if newAttrs[.paragraphStyle] == nil { newAttrs[.paragraphStyle] = NSMutableParagraphStyle() }
                let safeR = safeRange(range, for: attrString)
                attrString.setAttributes(newAttrs, range: safeR)
            }
            textView.attributedText = attrString
            textView.selectedRange = nsRange
        } else {
            // Toggle attribute in typingAttributes (for running style)
            var typingAttrs = textView.typingAttributes
            let currentValue = typingAttrs[attribute]
            let shouldRemove: Bool
            if let intValue = value as? Int, let currentInt = currentValue as? Int {
                shouldRemove = currentInt == intValue
            } else if let current = currentValue, "\(current)" == "\(value)" {
                shouldRemove = true
            } else {
                shouldRemove = false
            }
            if shouldRemove {
                typingAttrs[attribute] = 0
            } else {
                typingAttrs[attribute] = value
            }
            // Ensure font and paragraph style are present
            if typingAttrs[.font] == nil { typingAttrs[.font] = textView.font ?? UIFont.systemFont(ofSize: 16) }
            if typingAttrs[.paragraphStyle] == nil { typingAttrs[.paragraphStyle] = NSMutableParagraphStyle() }
            textView.typingAttributes = typingAttrs
        }
        updateToolbarButtonStates()
    }

    // MARK: - Toolbar Button Helpers
    private func createCircularToolbarButton(icon: String, action: Selector?, isMenu: Bool = false) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: icon), for: .normal)
        button.tintColor = .label
        button.backgroundColor = .clear
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        button.widthAnchor.constraint(equalToConstant: 32).isActive = true
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
        if let action = action { button.addTarget(self, action: action, for: .touchUpInside) }
        if isMenu { button.showsMenuAsPrimaryAction = true; button.setContentHuggingPriority(.required, for: .horizontal) }
        return button
    }

    private func createDivider() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemGray3
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([view.widthAnchor.constraint(equalToConstant: 1)])
        return view
    }

    private func textStyleMenu() -> UIMenu {
        return UIMenu(title: "", children: [
            UIAction(title: "Title") { [weak self] _ in self?.applyTextStyle(.title) },
            UIAction(title: "Heading") { [weak self] _ in self?.applyTextStyle(.heading) },
            UIAction(title: "Subhead") { [weak self] _ in self?.applyTextStyle(.subhead) },
            UIAction(title: "Body") { [weak self] _ in self?.applyTextStyle(.body) }
        ])
    }

    private func listMenu() -> UIMenu {
        return UIMenu(title: "List", children: [
            UIAction(title: "• Bullet", image: UIImage(systemName: "list.bullet")) { [weak self] _ in self?.insertListStyle(.bullet) },
            UIAction(title: "– Dash", image: UIImage(systemName: "minus")) { [weak self] _ in self?.insertListStyle(.dash) },
            UIAction(title: "○ Circle", image: UIImage(systemName: "circle")) { [weak self] _ in self?.insertListStyle(.circle) },
            UIAction(title: "Numbered List", image: UIImage(systemName: "list.number")) { [weak self] _ in self?.insertListStyle(.numbered) }
        ])
    }

    // MARK: - Text Style Enum
    enum NoteTextStyle { case title, heading, subhead, body }

    func applyTextStyle(_ style: NoteTextStyle) {
        guard let selectedRange = textView.selectedTextRange else { return }
        let start = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
        let length = textView.offset(from: selectedRange.start, to: selectedRange.end)
        let nsRange = NSRange(location: start, length: length)
        let attrString = NSMutableAttributedString(attributedString: textView.attributedText)

        // Define fonts and paragraph styles
        let font: UIFont
        let para = NSMutableParagraphStyle()
        switch style {
        case .title:
            font = UIFont.preferredFont(forTextStyle: .largeTitle)
            para.paragraphSpacing = 10
        case .heading:
            font = UIFont.preferredFont(forTextStyle: .title2)
            para.paragraphSpacing = 8
        case .subhead:
            font = UIFont.preferredFont(forTextStyle: .headline)
            para.paragraphSpacing = 6
        case .body:
            font = UIFont.preferredFont(forTextStyle: .body)
            para.paragraphSpacing = 4
        }

        if nsRange.length > 0 {
            // Apply to all paragraphs in selection
            let fullRange = safeRange(nsRange, for: attrString)
            attrString.enumerateAttribute(.paragraphStyle, in: fullRange, options: []) { _, range, _ in
                let safeR = safeRange(range, for: attrString)
                attrString.addAttribute(.font, value: font, range: safeR)
                attrString.addAttribute(.paragraphStyle, value: para, range: safeR)
            }
            textView.attributedText = attrString
            textView.selectedRange = fullRange
        } else {
            // No selection → apply to typingAttributes (running style)
            var typingAttrs = textView.typingAttributes
            typingAttrs[.font] = font
            typingAttrs[.paragraphStyle] = para
            textView.typingAttributes = typingAttrs
        }

        updateToolbarButtonStates()
    }

    // MARK: - List Formatting Enum
    private enum ListStyle { case bullet, dash, circle, numbered }

    private func insertListStyle(_ style: ListStyle) {
        guard let selectedRange = textView.selectedTextRange else { return }
        let start = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
        let length = textView.offset(from: selectedRange.start, to: selectedRange.end)
        let nsRange = NSRange(location: start, length: length)
        let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
        let selectedText = attrString.attributedSubstring(from: safeRange(nsRange, for: attrString)).string

        // Get full paragraph range for each affected line
        let linesRange = (attrString.string as NSString).lineRange(for: safeRange(nsRange, for: attrString))
        let lines = (attrString.string as NSString).substring(with: linesRange).components(separatedBy: "\n")
        var currentLocation = linesRange.location
        var number = 1
        for (i, line) in lines.enumerated() {
            let lineLength = (line as NSString).length
            let lineRange = NSRange(location: currentLocation, length: lineLength)
            let safeLineRange = safeRange(lineRange, for: attrString)
            // Remove all list prefixes
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            var newLine = trimmed
            // Remove any existing list prefix
            let listPrefixPatterns = ["^•\\s+", "^–\\s+", "^○\\s+", "^\\d+\\.\\s+"]
            for pattern in listPrefixPatterns {
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let range = NSRange(location: 0, length: (newLine as NSString).length)
                    newLine = regex.stringByReplacingMatches(in: newLine, options: [], range: range, withTemplate: "")
                }
            }
            // Add new prefix
            let prefix: String
            switch style {
            case .bullet: prefix = "• "
            case .dash:   prefix = "– "
            case .circle: prefix = "○ "
            case .numbered: prefix = "\(number). "
            }
            let withPrefix = prefix + newLine
            // Replace line in attrString
            let effectiveLocation = min(safeLineRange.location, attrString.length > 0 ? attrString.length - 1 : 0)
            let replacementAttrs = attrString.length > 0 ? attrString.attributes(at: effectiveLocation, effectiveRange: nil) : textView.typingAttributes
            let replacement = NSAttributedString(string: withPrefix, attributes: replacementAttrs)
            attrString.replaceCharacters(in: safeLineRange, with: replacement)
            let prefixLen = (prefix as NSString).length
            currentLocation += (withPrefix as NSString).length + 1 // +1 for \n
            if style == .numbered { number += 1 }
        }
        textView.attributedText = attrString
        // Restore selection
        let newRange = NSRange(location: linesRange.location, length: min(attrString.length - linesRange.location, linesRange.length + 32))
        textView.selectedRange = safeRange(newRange, for: attrString)
        updateToolbarButtonStates()
    }

    // MARK: - List Continuation on Newline
    // Helper to detect if a line is a list and return its prefix and style
    private func listPrefixAndStyle(for line: String) -> (String, ListStyle)? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("• ") {
            return ("• ", .bullet)
        } else if trimmed.hasPrefix("– ") {
            return ("– ", .dash)
        } else if trimmed.hasPrefix("○ ") {
            return ("○ ", .circle)
        } else if let match = trimmed.range(of: #"^(\d+)\.\s"#, options: .regularExpression) {
            // Extract number for numbered list
            let prefix = String(trimmed[..<match.upperBound])
            return (prefix, .numbered)
        }
        return nil
    }

    // MARK: - Toolbar Button Highlighting
    func updateToolbarButtonStates() {
        let textLength = textView.attributedText.length
        if textLength == 0 {
            // Use typingAttributes for empty document so running state is visible
            let typingAttrs = textView.typingAttributes
            let font = (typingAttrs[.font] as? UIFont) ?? UIFont.systemFont(ofSize: 16)
            let underline = typingAttrs[.underlineStyle] as? Int
            let strike = typingAttrs[.strikethroughStyle] as? Int
            // Highlight buttons based on typing attributes
            if font.fontDescriptor.symbolicTraits.contains(.traitBold) {
                boldButton.backgroundColor = UIColor.systemGray4
            } else {
                boldButton.backgroundColor = .clear
            }
            if font.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                italicButton.backgroundColor = UIColor.systemGray4
            } else {
                italicButton.backgroundColor = .clear
            }
            if let underline = underline, underline != 0 {
                underlineButton.backgroundColor = UIColor.systemGray4
            } else {
                underlineButton.backgroundColor = .clear
            }
            if let strike = strike, strike != 0 {
                strikethroughButton.backgroundColor = UIColor.systemGray4
            } else {
                strikethroughButton.backgroundColor = .clear
            }
            return
        }

        let range = textView.selectedRange
        let hasSelection = range.length > 0

        func setFormattingHighlights(font: UIFont, underline: Int?, strikethrough: Int?) {
            // Bold
            if font.fontDescriptor.symbolicTraits.contains(.traitBold) {
                boldButton.backgroundColor = UIColor.systemGray4
            } else {
                boldButton.backgroundColor = .clear
            }
            // Italic
            if font.fontDescriptor.symbolicTraits.contains(.traitItalic) {
                italicButton.backgroundColor = UIColor.systemGray4
            } else {
                italicButton.backgroundColor = .clear
            }
            // Underline
            if let underline = underline, underline != 0 {
                underlineButton.backgroundColor = UIColor.systemGray4
            } else {
                underlineButton.backgroundColor = .clear
            }
            // Strikethrough
            if let strike = strikethrough, strike != 0 {
                strikethroughButton.backgroundColor = UIColor.systemGray4
            } else {
                strikethroughButton.backgroundColor = .clear
            }
        }

        if hasSelection {
            // Use attributes at selection start (safe)
            let safeLoc = min(range.location, max(textView.attributedText.length-1,0))
            let attrs = textView.attributedText.attributes(at: safeLoc, effectiveRange: nil)
            let font = attrs[.font] as? UIFont ?? UIFont.systemFont(ofSize: 16)
            let underline = attrs[.underlineStyle] as? Int
            let strike = attrs[.strikethroughStyle] as? Int
            setFormattingHighlights(font: font, underline: underline, strikethrough: strike)
        } else {
            // No selection: use typingAttributes for formatting
            let typingAttrs = textView.typingAttributes
            let font = (typingAttrs[.font] as? UIFont) ?? UIFont.systemFont(ofSize: 16)
            let underline = typingAttrs[.underlineStyle] as? Int
            let strike = typingAttrs[.strikethroughStyle] as? Int
            setFormattingHighlights(font: font, underline: underline, strikethrough: strike)
        }
    }

    // MARK: - Safe NSRange Helper
    private func safeRange(_ range: NSRange, for attrString: NSAttributedString) -> NSRange {
        let loc = max(0, min(attrString.length, range.location))
        let len = max(0, min(attrString.length - loc, range.length))
        return NSRange(location: loc, length: len)
    }

    // MARK: - UITextViewDelegate
    func textViewDidChangeSelection(_ textView: UITextView) {
        updateToolbarButtonStates()
    }

    // Intercept Enter to continue list style and handle bullet insertion on empty lines
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // Only interested in Enter/newline
        guard text == "\n" else { return true }

        // Clamp range to prevent out-of-bounds
        let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
        let safeRange = self.safeRange(range, for: attrString)
        let nsText = attrString.string as NSString
        let lineRange = nsText.lineRange(for: safeRange)
        let lineText = nsText.substring(with: lineRange)

        // Handle list continuation
        if let (prefix, listStyle) = listPrefixAndStyle(for: lineText) {
            // Compute next prefix for numbered lists
            var nextPrefix = prefix
            if listStyle == .numbered {
                let pattern = #"^(\d+)\.\s"#
                if let regex = try? NSRegularExpression(pattern: pattern),
                    let match = regex.firstMatch(in: lineText, options: [], range: NSRange(location: 0, length: (lineText as NSString).length)),
                    match.numberOfRanges > 1
                {
                    let numberRange = match.range(at: 1)
                    let numberStr = (lineText as NSString).substring(with: numberRange)
                    if let number = Int(numberStr) {
                        nextPrefix = "\(number + 1). "
                    }
                }
            }
            // Attributes for new prefix: match previous line or typing attributes
            let prefixAttrs: [NSAttributedString.Key: Any]
            if lineRange.location < attrString.length {
                prefixAttrs = attrString.attributes(at: lineRange.location, effectiveRange: nil)
            } else {
                prefixAttrs = textView.typingAttributes
            }
            // Detect if line is empty (excluding prefix)
            let trimmedLine = lineText.trimmingCharacters(in: .whitespacesAndNewlines)
            let prefixOnly = trimmedLine == prefix.trimmingCharacters(in: .whitespaces)
            let isTrulyEmpty = trimmedLine.isEmpty
            if isTrulyEmpty || prefixOnly {
                // Insert only prefix at caret
                let prefixString = nextPrefix
                let newPrefixAttr = NSAttributedString(string: prefixString, attributes: prefixAttrs)
                let insertLoc = min(range.location, attrString.length)
                attrString.replaceCharacters(in: safeRange, with: newPrefixAttr)
                textView.attributedText = attrString
                textView.selectedRange = NSRange(location: insertLoc + prefixString.count, length: 0)
                textView.typingAttributes = prefixAttrs
                updateToolbarButtonStates()
                return false
            } else {
                // Insert newline and prefix
                let newLineString = "\n" + nextPrefix
                let newLineAttr = NSAttributedString(string: newLineString, attributes: prefixAttrs)
                let insertLoc = min(range.location, attrString.length)
                attrString.replaceCharacters(in: safeRange, with: newLineAttr)
                textView.attributedText = attrString
                textView.selectedRange = NSRange(location: insertLoc + newLineString.count, length: 0)
                textView.typingAttributes = prefixAttrs
                updateToolbarButtonStates()
                return false
            }
        }

        // If not a list line, allow normal behavior
        return true
    }
}

extension NoteEditorViewController {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        onEditingChanged?(true)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        onEditingChanged?(false)
    }
    
}
