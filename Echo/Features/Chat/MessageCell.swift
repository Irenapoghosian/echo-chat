import UIKit

/// A text or photo bubble: mine on the right in blue, theirs on the left in gray.
final class MessageCell: UITableViewCell {
    static let reuseID = "MessageCell"

    private let bubble = UIView()
    private let stack = UIStackView()
    private let quoteView = QuoteView()
    private let messageLabel = UILabel()
    private let photoView = UIImageView()
    private let timeLabel = UILabel()

    private var outgoingConstraints: [NSLayoutConstraint] = []
    private var incomingConstraints: [NSLayoutConstraint] = []
    private lazy var photoWidth = photoView.widthAnchor.constraint(equalToConstant: Self.photoSide)
    private lazy var photoHeight = photoView.heightAnchor.constraint(equalToConstant: 200)
    private var onPhotoTap: ((UIImage) -> Void)?

    static let photoSide: CGFloat = 220

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        configureViews()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// The bubble alone, lifted out of the list when the message menu opens.
    var bubbleView: UIView { bubble }

    override func prepareForReuse() {
        super.prepareForReuse()
        photoView.image = nil
        onPhotoTap = nil
    }

    func configure(with message: Message, contactName: String, onPhotoTap: @escaping (UIImage) -> Void) {
        let isMe = message.isFromMe
        NSLayoutConstraint.deactivate(isMe ? incomingConstraints : outgoingConstraints)
        NSLayoutConstraint.activate(isMe ? outgoingConstraints : incomingConstraints)

        // The corner nearest the sender stays square, like a speech bubble's tail.
        bubble.layer.maskedCorners = isMe
            ? [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner]
            : [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        timeLabel.text = ChatFormat.time(message.sentAt)
        accessibilityLabel = ChatFormat.accessibilityLabel(for: message, contactName: contactName)

        if let quote = message.replyTo {
            quoteView.configure(
                author: ChatFormat.author(of: quote.sender, contactName: contactName),
                summary: quote.summary,
                onBlue: isMe
            )
        }
        quoteView.isHidden = message.replyTo == nil

        switch message.content {
        case .text(let text):
            showText(text, isMe: isMe)
        case .image(let attachment):
            showPhoto(attachment.image, isMe: isMe, hasQuote: message.replyTo != nil, onTap: onPhotoTap)
        }
    }

    private func showText(_ text: String, isMe: Bool) {
        messageLabel.text = text
        messageLabel.isHidden = false
        photoView.isHidden = true
        NSLayoutConstraint.deactivate([photoWidth, photoHeight])
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        bubble.backgroundColor = isMe ? Theme.outgoingBubble : Theme.incomingBubble
        messageLabel.textColor = isMe ? Theme.outgoingText : Theme.incomingText
        accessibilityTraits = .staticText
        accessibilityHint = nil
        onPhotoTap = nil
    }

    private func showPhoto(_ image: UIImage, isMe: Bool, hasQuote: Bool, onTap: @escaping (UIImage) -> Void) {
        photoView.image = image
        messageLabel.isHidden = true
        photoView.isHidden = false
        photoHeight.constant = Self.photoHeight(fitting: image.size)
        NSLayoutConstraint.activate([photoWidth, photoHeight])
        if hasQuote {
            // A replied photo keeps its bubble, so the quote has something to sit on.
            stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
            bubble.backgroundColor = isMe ? Theme.outgoingBubble : Theme.incomingBubble
        } else {
            stack.directionalLayoutMargins = .zero
            bubble.backgroundColor = .clear
        }
        accessibilityTraits = [.image, .button]
        accessibilityHint = "Opens the photo full screen"
        onPhotoTap = onTap
    }

    /// Keeps tall and wide photos within sensible proportions.
    static func photoHeight(fitting size: CGSize) -> CGFloat {
        guard size.width > 0, size.height > 0 else { return photoSide }
        let ratio = min(max(size.height / size.width, 0.5), 1.4)
        return (photoSide * ratio).rounded()
    }

    // MARK: - Setup

    private func configureViews() {
        bubble.layer.cornerRadius = Theme.bubbleRadius
        bubble.layer.cornerCurve = .continuous
        bubble.clipsToBounds = true

        messageLabel.numberOfLines = 0
        messageLabel.font = Theme.font(.body)
        messageLabel.adjustsFontForContentSizeCategory = true

        photoView.contentMode = .scaleAspectFill
        photoView.clipsToBounds = true
        photoView.isUserInteractionEnabled = true
        photoView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(photoTapped)))

        timeLabel.font = Theme.font(.caption2)
        timeLabel.adjustsFontForContentSizeCategory = true
        timeLabel.textColor = .secondaryLabel

        stack.axis = .vertical
        stack.spacing = 6
        stack.isLayoutMarginsRelativeArrangement = true
        stack.addArrangedSubview(quoteView)
        stack.addArrangedSubview(messageLabel)
        stack.addArrangedSubview(photoView)

        isAccessibilityElement = true
    }

    private func configureLayout() {
        [bubble, stack, timeLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        contentView.addSubview(bubble)
        contentView.addSubview(timeLabel)
        bubble.addSubview(stack)

        // Just below required, so they never fight the cell's own height during layout passes.
        photoWidth.priority = .defaultHigh
        photoHeight.priority = .defaultHigh

        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 3),
            bubble.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),
            stack.topAnchor.constraint(equalTo: bubble.topAnchor),
            stack.bottomAnchor.constraint(equalTo: bubble.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: bubble.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: bubble.trailingAnchor),
            timeLabel.topAnchor.constraint(equalTo: bubble.bottomAnchor, constant: 3),
            timeLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
        ])

        outgoingConstraints = [
            bubble.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
            timeLabel.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -4),
        ]
        incomingConstraints = [
            bubble.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            timeLabel.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 4),
        ]
    }

    @objc private func photoTapped() {
        guard let image = photoView.image else { return }
        onPhotoTap?(image)
    }
}
