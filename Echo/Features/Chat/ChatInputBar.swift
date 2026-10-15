import UIKit

protocol ChatInputBarDelegate: AnyObject {
    func inputBar(_ inputBar: ChatInputBar, didSend text: String)
    func inputBarDidTapPhoto(_ inputBar: ChatInputBar)
    func inputBarDidCancelReply(_ inputBar: ChatInputBar)
}

/// The composer, used as the chat's `inputAccessoryView`: it rides on top of the keyboard,
/// grows with the text up to five lines, then scrolls. While replying, the quote sits above it.
final class ChatInputBar: UIView {
    weak var delegate: ChatInputBarDelegate?

    private let replyQuote = QuoteView()
    private let cancelReplyButton = UIButton(type: .system)
    private lazy var replyBanner = UIStackView(arrangedSubviews: [replyQuote, cancelReplyButton])
    private let inputRow = UIView()
    private let textView = UITextView()
    private let placeholder = UILabel()
    private let photoButton = UIButton(type: .system)
    private let sendButton = UIButton(type: .system)
    private let maxTextHeight: CGFloat = 120
    private lazy var fixedTextHeight = textView.heightAnchor.constraint(equalToConstant: maxTextHeight)

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Lets Auto Layout size the bar; together with `intrinsicContentSize` = .zero
        // this is how an input accessory view grows with its content.
        autoresizingMask = .flexibleHeight
        configureViews()
        configureLayout()
        updateState()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: CGSize { .zero }

    // MARK: - Replying

    func showReply(author: String, summary: String) {
        replyQuote.configure(author: author, summary: summary)
        replyQuote.accessibilityLabel = "Replying to \(author): \(summary)"
        replyBanner.isHidden = false
    }

    func hideReply() {
        replyBanner.isHidden = true
    }

    func focus() {
        textView.becomeFirstResponder()
    }

    // MARK: - Setup

    private func configureViews() {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        blur.frame = bounds
        blur.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(blur)

        let symbols = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        photoButton.setImage(UIImage(systemName: "plus.circle.fill", withConfiguration: symbols), for: .normal)
        photoButton.accessibilityLabel = "Send a photo"
        photoButton.addTarget(self, action: #selector(photoTapped), for: .touchUpInside)

        sendButton.setImage(UIImage(systemName: "arrow.up.circle.fill", withConfiguration: symbols), for: .normal)
        sendButton.accessibilityLabel = "Send"
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)

        textView.font = Theme.font(.body)
        textView.adjustsFontForContentSizeCategory = true
        textView.isScrollEnabled = false
        textView.backgroundColor = .systemBackground
        textView.layer.cornerRadius = 18
        textView.layer.cornerCurve = .continuous
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        textView.delegate = self
        textView.accessibilityLabel = "Message"

        placeholder.text = "Message"
        placeholder.font = textView.font
        placeholder.adjustsFontForContentSizeCategory = true
        placeholder.textColor = .placeholderText
        placeholder.isAccessibilityElement = false

        cancelReplyButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        cancelReplyButton.tintColor = .secondaryLabel
        cancelReplyButton.accessibilityLabel = "Cancel reply"
        cancelReplyButton.addTarget(self, action: #selector(cancelReplyTapped), for: .touchUpInside)
        cancelReplyButton.setContentHuggingPriority(.required, for: .horizontal)
        replyQuote.isAccessibilityElement = true
        replyBanner.spacing = 8
        replyBanner.alignment = .center
        replyBanner.isLayoutMarginsRelativeArrangement = true
        replyBanner.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 2, leading: 10, bottom: 4, trailing: 4)
        replyBanner.isHidden = true
    }

    private func configureLayout() {
        [photoButton, textView, sendButton, placeholder].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            inputRow.addSubview($0)
        }
        let column = UIStackView(arrangedSubviews: [replyBanner, inputRow])
        column.axis = .vertical
        column.spacing = 4
        column.translatesAutoresizingMaskIntoConstraints = false
        addSubview(column)

        let separator = UIView()
        separator.backgroundColor = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separator)

        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: topAnchor),
            separator.leadingAnchor.constraint(equalTo: leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: trailingAnchor),
            separator.heightAnchor.constraint(equalToConstant: 0.5),

            column.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            column.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -8),
            column.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 8),
            column.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -8),
        ])
        layoutInputRow()
    }

    private func layoutInputRow() {
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: inputRow.topAnchor),
            textView.bottomAnchor.constraint(equalTo: inputRow.bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: photoButton.trailingAnchor, constant: 6),
            textView.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -6),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),

            photoButton.leadingAnchor.constraint(equalTo: inputRow.leadingAnchor),
            photoButton.bottomAnchor.constraint(equalTo: textView.bottomAnchor),
            photoButton.widthAnchor.constraint(equalToConstant: 36),
            photoButton.heightAnchor.constraint(equalToConstant: 36),

            sendButton.trailingAnchor.constraint(equalTo: inputRow.trailingAnchor),
            sendButton.bottomAnchor.constraint(equalTo: textView.bottomAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 36),
            sendButton.heightAnchor.constraint(equalToConstant: 36),

            placeholder.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 15),
            placeholder.centerYAnchor.constraint(equalTo: textView.centerYAnchor),
        ])
    }

    private var trimmedText: String {
        textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func updateState() {
        placeholder.isHidden = !textView.text.isEmpty
        sendButton.isEnabled = !trimmedText.isEmpty

        // Grow line by line, then switch to scrolling at a fixed height.
        let fitting = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: .greatestFiniteMagnitude))
        let tooTall = fitting.height > maxTextHeight
        if textView.isScrollEnabled != tooTall {
            textView.isScrollEnabled = tooTall
            fixedTextHeight.isActive = tooTall
            invalidateIntrinsicContentSize()
        }
    }

    @objc private func sendTapped() {
        guard !trimmedText.isEmpty else { return }
        delegate?.inputBar(self, didSend: trimmedText)
        textView.text = ""
        updateState()
    }

    @objc private func photoTapped() {
        delegate?.inputBarDidTapPhoto(self)
    }

    @objc private func cancelReplyTapped() {
        delegate?.inputBarDidCancelReply(self)
    }
}

extension ChatInputBar: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        updateState()
    }
}
