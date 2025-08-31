//
//  NoteEditorViewController.swift
//  MannKiBaat
//

import UIKit
import SwiftUI
import SwiftData
import SharedModels

class NoteEditorViewController: UIViewController {

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

    // MARK: - Init
    init(note: NoteModel, viewModel: NotesViewModel, modelContext: ModelContext) {
        self.note = note
        self.viewModel = viewModel
        self.modelContext = modelContext
        // If the note has no identifier or is empty, treat as new note
        if note.id == nil || (note.title.isEmpty && note.attributedContent.length == 0) {
            self.isNewNote = true
        } else {
            self.isNewNote = false
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

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

    deinit { NotificationCenter.default.removeObserver(self) }

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
        // Apple Notes-style text style menu
        let styleMenuButton = createTextStyleMenuButton()
        toolbarStackView.addArrangedSubview(styleMenuButton)
        toolbarStackView.addArrangedSubview(createDivider())
        toolbarStackView.addArrangedSubview(createFormatButton(title: "B", action: #selector(toggleBold), font: .boldSystemFont(ofSize: 16)))
        toolbarStackView.addArrangedSubview(createFormatButton(title: "I", action: #selector(toggleItalic), font: .italicSystemFont(ofSize: 16)))
        toolbarStackView.addArrangedSubview(createFormatButton(icon: "underline", action: #selector(toggleUnderlineFormatting)))
        toolbarStackView.addArrangedSubview(createFormatButton(icon: "strikethrough", action: #selector(toggleStrikethrough)))
        toolbarStackView.addArrangedSubview(createDivider())
        toolbarStackView.addArrangedSubview(createFormatButton(icon: "list.bullet", action: #selector(toggleBulletList)))
        toolbarStackView.addArrangedSubview(createFormatButton(icon: "list.number", action: #selector(toggleNumberedList)))
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
        // If this is a new note, clear the textView
        if isNewNote {
            textView.attributedText = NSAttributedString(string: "")
        } else {
            let combined = NSMutableAttributedString()
            if !note.title.isEmpty {
                combined.append(NSAttributedString(string: note.title, attributes: [.font: UIFont.preferredFont(forTextStyle: .body)]))
                if note.attributedContent.length > 0 {
                    combined.append(NSAttributedString(string: "\n"))
                    combined.append(note.attributedContent)
                }
            } else if note.attributedContent.length > 0 {
                combined.append(note.attributedContent)
            }
            textView.attributedText = combined
        }
    }

    private func saveNote() {
        let fullString = textView.attributedText.string
        var title = ""
        var content = NSAttributedString(string: "")
        if let newlineIdx = fullString.firstIndex(of: "\n") {
            title = String(fullString[..<newlineIdx])
            let bodyStart = fullString.index(after: newlineIdx)
            content = textView.attributedText.attributedSubstring(
                from: NSRange(
                    location: fullString.distance(from: fullString.startIndex, to: bodyStart),
                    length: fullString.distance(from: bodyStart, to: fullString.endIndex)
                )
            )
        } else {
            title = fullString
            content = NSAttributedString(string: "")
        }

        // Only create a new note if the note has no id or both title/content are empty (i.e. truly new)
        let shouldCreateNewNote = (note.id == nil || (note.title.isEmpty && note.attributedContent.length == 0))
        if shouldCreateNewNote {
            // Create a new note and add to context, using richTextData for storage
            let newNote = NoteModel(title: title, richTextData: content.archivedData())
            Task { @MainActor in
                await viewModel.addNote(newNote, in: modelContext)
            }
            // Update the note reference to the new note
            self.note = newNote
            self.isNewNote = false
        } else {
            // Update the existing note using the attributedContent computed property
            note.title = title
            note.attributedContent = content
            Task { @MainActor in
                await viewModel.updateNote(note, in: modelContext)
            }
            // Do not set isNewNote to false here, as we did not create a new note
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
        currentAttrText.addAttribute(attribute, value: value, range: nsRange)
        textView.attributedText = currentAttrText
        textView.selectedRange = nsRange
    }

    // MARK: - Notes-style list functions
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
}

// MARK: - UITextViewDelegate
extension NoteEditorViewController: UITextViewDelegate {
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
}

// MARK: - Toolbar Button Helpers
private extension NoteEditorViewController {
    func createFormatButton(title: String, action: Selector, font: UIFont? = nil) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = font ?? UIFont.systemFont(ofSize: 16)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    func createFormatButton(icon: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: icon), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    func createDivider() -> UIView {
        let view = UIView()
        view.backgroundColor = .systemGray3
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([view.widthAnchor.constraint(equalToConstant: 1)])
        return view
    }
}


// MARK: - Text Style Menu
extension NoteEditorViewController {
    private func createTextStyleMenuButton() -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Aa", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.showsMenuAsPrimaryAction = true
        let menu = UIMenu(title: "", children: [
            UIAction(title: "Title", handler: { _ in self.applyTextStyle(.title) }),
            UIAction(title: "Heading", handler: { _ in self.applyTextStyle(.heading) }),
            UIAction(title: "Subhead", handler: { _ in self.applyTextStyle(.subhead) }),
            UIAction(title: "Body", handler: { _ in self.applyTextStyle(.body) })
        ])
        button.menu = menu
        return button
    }

    enum NoteTextStyle {
        case title
        case heading
        case subhead
        case body
    }

    /// Apply Apple Notes-style text style formatting, preserving bold/italic
    func applyTextStyle(_ style: NoteTextStyle) {
        guard let selectedRange = textView.selectedTextRange else { return }
        let start = textView.offset(from: textView.beginningOfDocument, to: selectedRange.start)
        let end = textView.offset(from: textView.beginningOfDocument, to: selectedRange.end)
        let nsRange = NSRange(location: start, length: end - start)
        let attrString = NSMutableAttributedString(attributedString: textView.attributedText)

        // Determine font and paragraph spacing for style
        let (font, paragraphSpacingBefore, paragraphSpacingAfter) = fontForTextStyle(style)

        // Apply font, preserving symbolic traits (bold, italic)
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

        // Apply paragraph style for spacing
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

        // If selection is empty, update typingAttributes
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
            // Large bold, e.g. Apple Notes
            return (UIFont.systemFont(ofSize: 28, weight: .bold), 0, 10)
        case .heading:
            return (UIFont.systemFont(ofSize: 20, weight: .semibold), 0, 8)
        case .subhead:
            return (UIFont.systemFont(ofSize: 16, weight: .medium), 0, 6)
        case .body:
            return (UIFont.preferredFont(forTextStyle: .body), 0, 2)
        }
    }
}
