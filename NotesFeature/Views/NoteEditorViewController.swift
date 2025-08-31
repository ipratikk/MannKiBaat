//
//  NoteEditorViewController.swift
//  MannKiBaat
//

import UIKit
import SwiftUI
import SwiftData
import SharedModels

class NoteEditorViewController: UIViewController, UITextViewDelegate {

    // MARK: - Properties
    var note: NoteModel
    var viewModel: NotesViewModel
    var modelContext: ModelContext
    var onDismiss: (() -> Void)?
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

    // MARK: - Toolbar Buttons
    private var boldButton: UIButton!
    private var italicButton: UIButton!
    private var underlineButton: UIButton!
    private var strikethroughButton: UIButton!
    private var bulletButton: UIButton!
    private var numberButton: UIButton!
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveNote()
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

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textView.bottomAnchor.constraint(equalTo: toolbarContainer.topAnchor),

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
        bulletButton = createCircularToolbarButton(icon: "list.bullet", action: #selector(toggleBulletList))
        numberButton = createCircularToolbarButton(icon: "list.number", action: #selector(toggleNumberedList))
        toolbarStackView.addArrangedSubview(bulletButton)
        toolbarStackView.addArrangedSubview(numberButton)
    }

    // MARK: - Keyboard
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        toolbarBottomConstraint.constant = -keyboardFrame.height + view.safeAreaInsets.bottom
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        toolbarBottomConstraint.constant = 0
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    // MARK: - Content
    private func loadNoteContent() {
        if isNewNote {
            textView.attributedText = NSAttributedString(string: "")
        } else {
            textView.attributedText = note.attributedContent
        }
    }

    private func saveNote() {
        let attributed = textView.attributedText ?? NSAttributedString(string: "")
        let fullString = attributed.string
        let isContentEmpty = fullString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        let title: String
        if let newlineIdx = fullString.firstIndex(of: "\n") {
            title = String(fullString[..<newlineIdx])
        } else {
            title = fullString
        }

        if isContentEmpty {
            if isNewNote {
                return
            } else {
                let noteToDelete = note
                Task { @MainActor in
                    await viewModel.removeNote(noteToDelete, in: modelContext)
                }
                return
            }
        }

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
    @objc private func doneButtonTapped() {
        saveNote()
        dismiss(animated: true)
    }

    @objc private func toggleBold() { toggleTrait(.traitBold) }
    @objc private func toggleItalic() { toggleTrait(.traitItalic) }
    @objc private func toggleUnderlineFormatting() { toggleAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue) }
    @objc private func toggleStrikethrough() { toggleAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue) }
    @objc private func toggleBulletList() { insertPrefix("• ") }
    @objc private func toggleNumberedList() { insertNumberedList() }

    // MARK: - Formatting Logic
    private func toggleTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
        guard let selectedRange = textView.selectedTextRange else { return }
        let start = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
        let length = textView.offset(from: selectedRange.start, to: selectedRange.end)
        let nsRange = NSRange(location: start, length: length)
        let currentAttrText = NSMutableAttributedString(attributedString: textView.attributedText)

        currentAttrText.enumerateAttribute(.font, in: nsRange, options: []) { value, range, _ in
            let currentFont = value as? UIFont ?? UIFont.systemFont(ofSize: 16)
            var traits = currentFont.fontDescriptor.symbolicTraits
            if traits.contains(trait) { traits.remove(trait) } else { traits.insert(trait) }
            if let descriptor = currentFont.fontDescriptor.withSymbolicTraits(traits) {
                let newFont = UIFont(descriptor: descriptor, size: currentFont.pointSize)
                currentAttrText.addAttribute(.font, value: newFont, range: range)
            }
        }

        textView.attributedText = currentAttrText
        textView.selectedRange = nsRange
    }

    private func toggleAttribute(_ attribute: NSAttributedString.Key, value: Any) {
        guard let selectedRange = textView.selectedTextRange else { return }
        let start = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
        let length = textView.offset(from: selectedRange.start, to: selectedRange.end)
        let nsRange = NSRange(location: start, length: length)
        let currentAttrText = NSMutableAttributedString(attributedString: textView.attributedText)

        currentAttrText.enumerateAttributes(in: nsRange, options: []) { attrs, range, _ in
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
            if shouldRemove {
                newAttrs[attribute] = 0
            } else {
                newAttrs[attribute] = value
            }
            if newAttrs[.font] == nil {
                newAttrs[.font] = textView.font ?? UIFont.systemFont(ofSize: 16)
            }
            if newAttrs[.paragraphStyle] == nil {
                let para = NSMutableParagraphStyle()
                newAttrs[.paragraphStyle] = para
            }
            currentAttrText.setAttributes(newAttrs, range: range)
        }

        textView.attributedText = currentAttrText
        textView.selectedRange = nsRange
    }

    // MARK: - List Formatting
    private func insertPrefix(_ prefix: String) {
        guard let range = textView.selectedTextRange else { return }
        let cursorPos = textView.offset(from: textView.beginningOfDocument, to: range.start)
        let fullText = textView.text as NSString
        let lineRange = fullText.lineRange(for: NSRange(location: max(0, cursorPos - 1), length: 0))
        let lineText = fullText.substring(with: lineRange).trimmingCharacters(in: .newlines)
        let attrs = textView.typingAttributes

        if lineText.hasPrefix(prefix.trimmingCharacters(in: .whitespaces)) {
            let newText = String(lineText.dropFirst(prefix.count))
            textView.textStorage.replaceCharacters(in: lineRange, with: NSAttributedString(string: newText + "\n", attributes: attrs))
            textView.selectedRange = NSRange(location: lineRange.location + newText.count, length: 0)
        } else {
            let newText = prefix + lineText
            textView.textStorage.replaceCharacters(in: lineRange, with: NSAttributedString(string: newText + "\n", attributes: attrs))
            textView.selectedRange = NSRange(location: lineRange.location + newText.count, length: 0)
        }
    }

    private func insertNumberedList() {
        guard let range = textView.selectedTextRange else { return }
        let cursorPos = textView.offset(from: textView.beginningOfDocument, to: range.start)
        let fullText = textView.text as NSString
        let lineRange = fullText.lineRange(for: NSRange(location: max(0, cursorPos - 1), length: 0))
        let lineText = fullText.substring(with: lineRange).trimmingCharacters(in: .newlines)
        let attrs = textView.typingAttributes

        let numberedPattern = #"^\d+\.\s"#
        let regex = try? NSRegularExpression(pattern: numberedPattern)
        if let match = regex?.firstMatch(in: lineText, range: NSRange(location: 0, length: lineText.utf16.count)) {
            let withoutNumber = String(lineText.dropFirst(match.range.length))
            textView.textStorage.replaceCharacters(in: lineRange, with: NSAttributedString(string: withoutNumber + "\n", attributes: attrs))
            textView.selectedRange = NSRange(location: lineRange.location + withoutNumber.count, length: 0)
        } else {
            let newText = "1. " + lineText
            textView.textStorage.replaceCharacters(in: lineRange, with: NSAttributedString(string: newText + "\n", attributes: attrs))
            textView.selectedRange = NSRange(location: lineRange.location + newText.count, length: 0)
        }
    }

    // MARK: - Toolbar Button Helpers
    private func createCircularToolbarButton(icon: String, action: Selector?, isMenu: Bool = false) -> UIButton {
        let button = UIButton(type: .system)
        let image = UIImage(systemName: icon)
        button.setImage(image, for: .normal)
        button.tintColor = .label
        button.imageView?.contentMode = .scaleAspectFit
        button.backgroundColor = .clear
        button.layer.cornerRadius = 16
        button.clipsToBounds = true
        button.widthAnchor.constraint(equalToConstant: 32).isActive = true
        button.heightAnchor.constraint(equalToConstant: 32).isActive = true
        if let action = action {
            button.addTarget(self, action: action, for: .touchUpInside)
        }
        if isMenu {
            button.setContentHuggingPriority(.required, for: .horizontal)
            button.showsMenuAsPrimaryAction = true
        }
        return button
    }

    private func createDivider() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemGray3
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([view.widthAnchor.constraint(equalToConstant: 1)])
        return view
    }

    // MARK: - Text Style Menu
    private func textStyleMenu() -> UIMenu {
        return UIMenu(title: "", children: [
            UIAction(title: "Title", handler: { _ in self.applyTextStyle(.title) }),
            UIAction(title: "Heading", handler: { _ in self.applyTextStyle(.heading) }),
            UIAction(title: "Subhead", handler: { _ in self.applyTextStyle(.subhead) }),
            UIAction(title: "Body", handler: { _ in self.applyTextStyle(.body) })
        ])
    }

    // MARK: - Toolbar Button State Highlighting
    func updateToolbarButtonStates() {
        guard let selectedRange = textView.selectedTextRange else { return }
        let start = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
        let length = textView.offset(from: selectedRange.start, to: selectedRange.end)
        guard let attrText = textView.attributedText else { return }
        let attrTextLen = attrText.length
        let safeLength = min(length, max(0, attrTextLen - start))
        if safeLength <= 0 && attrTextLen == 0 {
            if let boldButton = boldButton {
                boldButton.backgroundColor = .clear
                boldButton.tintColor = .label
            }
            if let italicButton = italicButton {
                italicButton.backgroundColor = .clear
                italicButton.tintColor = .label
            }
            if let underlineButton = underlineButton {
                underlineButton.backgroundColor = .clear
                underlineButton.tintColor = .label
            }
            if let strikethroughButton = strikethroughButton {
                strikethroughButton.backgroundColor = .clear
                strikethroughButton.tintColor = .label
            }
            if let bulletButton = bulletButton {
                bulletButton.backgroundColor = .clear
                bulletButton.tintColor = .label
            }
            if let numberButton = numberButton {
                numberButton.backgroundColor = .clear
                numberButton.tintColor = .label
            }
            return
        }
        let nsRange = NSRange(location: start, length: safeLength > 0 ? safeLength : 1)
        let fullText = attrText.string as NSString
        func isTraitActive(_ trait: UIFontDescriptor.SymbolicTraits) -> Bool {
            if attrText.length == 0 { return false }
            var found = false
            let effectiveRange = nsRange
            // Clamp the effectiveRange to be within the bounds of attrText
            let maxLen = attrText.length
            let safeLoc = max(0, min(effectiveRange.location, maxLen))
            let safeLen = max(0, min(effectiveRange.length, maxLen - safeLoc))
            let checkedRange = NSRange(location: safeLoc, length: safeLen)
            attrText.enumerateAttribute(.font, in: checkedRange, options: []) { value, _, stop in
                let font = value as? UIFont ?? UIFont.systemFont(ofSize: 16)
                if font.fontDescriptor.symbolicTraits.contains(trait) {
                    found = true; stop.pointee = true
                }
            }
            return found
        }
        func isAttributeActive(_ attribute: NSAttributedString.Key, value: Int) -> Bool {
            if attrText.length == 0 { return false }
            var found = false
            let effectiveRange = nsRange
            // Clamp the effectiveRange to be within the bounds of attrText
            let maxLen = attrText.length
            let safeLoc = max(0, min(effectiveRange.location, maxLen))
            let safeLen = max(0, min(effectiveRange.length, maxLen - safeLoc))
            let checkedRange = NSRange(location: safeLoc, length: safeLen)
            attrText.enumerateAttribute(attribute, in: checkedRange, options: []) { val, _, stop in
                if let v = val as? Int, v == value {
                    found = true; stop.pointee = true
                }
            }
            return found
        }
        func currentLineHasPrefix(_ prefix: String, numbered: Bool = false) -> Bool {
            let cursor = start
            // Defensive: Clamp cursor and lineRange to valid bounds
            let textLen = fullText.length
            let cursorClamped = max(0, min(cursor, textLen > 0 ? textLen - 1 : 0))
            let lineRange = fullText.lineRange(for: NSRange(location: cursorClamped, length: 0))
            // Clamp lineRange to fit within string bounds
            let safeLocation = max(0, min(lineRange.location, textLen))
            let safeLength = max(0, min(lineRange.length, textLen - safeLocation))
            let safeRange = NSRange(location: safeLocation, length: safeLength)
            guard safeRange.location + safeRange.length <= textLen else { return false }
            let lineText = fullText.substring(with: safeRange).trimmingCharacters(in: .newlines)
            if numbered {
                let pattern = #"^\d+\.\s"#
                if let regex = try? NSRegularExpression(pattern: pattern) {
                    let matches = regex.matches(in: lineText, range: NSRange(location: 0, length: lineText.utf16.count))
                    return !matches.isEmpty
                }
                return false
            }
            return lineText.hasPrefix(prefix)
        }
        // Safely update bold button
        if let boldButton = boldButton {
            boldButton.backgroundColor = isTraitActive(.traitBold) ? UIColor.systemBlue.withAlphaComponent(0.18) : .clear
            boldButton.tintColor = isTraitActive(.traitBold) ? .systemBlue : .label
        }
        if let italicButton = italicButton {
            italicButton.backgroundColor = isTraitActive(.traitItalic) ? UIColor.systemBlue.withAlphaComponent(0.18) : .clear
            italicButton.tintColor = isTraitActive(.traitItalic) ? .systemBlue : .label
        }
        if let underlineButton = underlineButton {
            underlineButton.backgroundColor = isAttributeActive(.underlineStyle, value: NSUnderlineStyle.single.rawValue) ? UIColor.systemBlue.withAlphaComponent(0.18) : .clear
            underlineButton.tintColor = isAttributeActive(.underlineStyle, value: NSUnderlineStyle.single.rawValue) ? .systemBlue : .label
        }
        if let strikethroughButton = strikethroughButton {
            strikethroughButton.backgroundColor = isAttributeActive(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue) ? UIColor.systemBlue.withAlphaComponent(0.18) : .clear
            strikethroughButton.tintColor = isAttributeActive(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue) ? .systemBlue : .label
        }
        if let bulletButton = bulletButton {
            bulletButton.backgroundColor = currentLineHasPrefix("• ") ? UIColor.systemBlue.withAlphaComponent(0.18) : .clear
            bulletButton.tintColor = currentLineHasPrefix("• ") ? .systemBlue : .label
        }
        if let numberButton = numberButton {
            numberButton.backgroundColor = currentLineHasPrefix("", numbered: true) ? UIColor.systemBlue.withAlphaComponent(0.18) : .clear
            numberButton.tintColor = currentLineHasPrefix("", numbered: true) ? .systemBlue : .label
        }
    }

    private func highlightToolbarButton(_ button: UIButton?, active: Bool) {
        guard let button = button else { return }
        if active {
            button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.18)
            button.tintColor = .systemBlue
        } else {
            button.backgroundColor = .clear
            button.tintColor = .label
        }
    }

    // MARK: - Text Style Enum and Application
    enum NoteTextStyle {
        case title
        case heading
        case subhead
        case body
    }

    func applyTextStyle(_ style: NoteTextStyle) {
        guard let selectedRange = textView.selectedTextRange else { return }
        let start = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
        let end = textView.offset(from: textView.beginningOfDocument, to: selectedRange.end)
        let nsRange = NSRange(location: start, length: end - start)
        let attrString = NSMutableAttributedString(attributedString: textView.attributedText)
        let (font, paragraphSpacingBefore, paragraphSpacingAfter) = fontForTextStyle(style)
        attrString.enumerateAttribute(.font, in: nsRange, options: []) { value, range, _ in
            let currentFont = (value as? UIFont) ?? UIFont.preferredFont(forTextStyle: .body)
            let traits = currentFont.fontDescriptor.symbolicTraits
            var descriptor = font.fontDescriptor
            if let withTraits = descriptor.withSymbolicTraits(traits) {
                descriptor = withTraits
            }
            let newFont = UIFont(descriptor: descriptor, size: font.pointSize)
            attrString.addAttribute(.font, value: newFont, range: range)
        }
        attrString.enumerateAttribute(.paragraphStyle, in: nsRange, options: []) { value, range, _ in
            let para: NSMutableParagraphStyle
            if let existing = value as? NSMutableParagraphStyle {
                para = existing
            } else if let existing = value as? NSParagraphStyle {
                para = existing.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            } else {
                para = NSMutableParagraphStyle()
            }
            para.paragraphSpacingBefore = paragraphSpacingBefore
            para.paragraphSpacing = paragraphSpacingAfter
            attrString.addAttribute(.paragraphStyle, value: para, range: range)
        }
        if nsRange.length == 0 {
            var newTypingAttrs = textView.typingAttributes
            newTypingAttrs[NSAttributedString.Key.font] = font
            let para: NSMutableParagraphStyle
            if let existing = newTypingAttrs[NSAttributedString.Key.paragraphStyle] as? NSMutableParagraphStyle {
                para = existing
            } else if let existing = newTypingAttrs[NSAttributedString.Key.paragraphStyle] as? NSParagraphStyle {
                para = existing.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
            } else {
                para = NSMutableParagraphStyle()
            }
            para.paragraphSpacingBefore = paragraphSpacingBefore
            para.paragraphSpacing = paragraphSpacingAfter
            newTypingAttrs[NSAttributedString.Key.paragraphStyle] = para
            textView.typingAttributes = newTypingAttrs
        }
        textView.attributedText = attrString
        textView.selectedRange = nsRange
    }

    private func fontForTextStyle(_ style: NoteTextStyle) -> (UIFont, CGFloat, CGFloat) {
        switch style {
        case .title:
            return (UIFont.systemFont(ofSize: 28, weight: .bold), 0, 10)
        case .heading:
            return (UIFont.systemFont(ofSize: 20, weight: .semibold), 0, 8)
        case .subhead:
            return (UIFont.systemFont(ofSize: 16, weight: .medium), 0, 6)
        case .body:
            return (UIFont.preferredFont(forTextStyle: .body), 0, 2)
        }
    }

    // MARK: - UITextViewDelegate Methods
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text == "\n" else { return true }
        let fullText = textView.text as NSString
        let cursorLocation = range.location
        let lineRange = fullText.lineRange(for: NSRange(location: max(0, cursorLocation - 1), length: 0))
        let currentLine = fullText.substring(with: lineRange)
        let attrs = textView.typingAttributes
        let bulletPrefix = "• "
        if currentLine.hasPrefix(bulletPrefix) {
            let trimmed = currentLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed == bulletPrefix.trimmingCharacters(in: .whitespaces) {
                textView.textStorage.replaceCharacters(in: lineRange, with: NSAttributedString(string: ""))
                textView.selectedRange = NSRange(location: lineRange.location, length: 0)
            } else {
                let insertAttr = NSAttributedString(string: "\n" + bulletPrefix, attributes: attrs)
                textView.textStorage.replaceCharacters(in: range, with: insertAttr)
                textView.selectedRange = NSRange(location: range.location + insertAttr.length, length: 0)
            }
            return false
        }
        let numberedPattern = #"^(\d+)\.\s"#
        if let regex = try? NSRegularExpression(pattern: numberedPattern),
           let match = regex.firstMatch(in: currentLine, range: NSRange(location: 0, length: currentLine.utf16.count)) {
            let matchedPrefix = (currentLine as NSString).substring(with: match.range)
            let trimmed = currentLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed == matchedPrefix.trimmingCharacters(in: .whitespaces) {
                textView.textStorage.replaceCharacters(in: lineRange, with: NSAttributedString(string: ""))
                textView.selectedRange = NSRange(location: lineRange.location, length: 0)
            } else {
                let numberString = matchedPrefix.dropLast(2)
                if let number = Int(numberString) {
                    let nextNumber = number + 1
                    let insertAttr = NSAttributedString(string: "\n\(nextNumber). ", attributes: attrs)
                    textView.textStorage.replaceCharacters(in: range, with: insertAttr)
                    textView.selectedRange = NSRange(location: range.location + insertAttr.length, length: 0)
                }
            }
            return false
        }
        return true
    }

    func textViewDidChangeSelection(_ textView: UITextView) {
        updateToolbarButtonStates()
    }
}
