import UIKit

/// The navigation bar title: the contact's name with "online" or "typing…" under it.
final class ChatTitleView: UIView {
    private let nameLabel = UILabel()
    private let statusLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        nameLabel.font = Theme.font(.headline, weight: .semibold)
        statusLabel.font = Theme.font(.caption1)
        [nameLabel, statusLabel].forEach {
            $0.textAlignment = .center
            $0.adjustsFontForContentSizeCategory = true
        }

        let stack = UIStackView(arrangedSubviews: [nameLabel, statusLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        isAccessibilityElement = true
        accessibilityTraits = .header
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(name: String, isTyping: Bool) {
        nameLabel.text = name
        statusLabel.text = isTyping ? "typing…" : "online"
        statusLabel.textColor = isTyping ? .tintColor : .secondaryLabel
        accessibilityLabel = "\(name), \(statusLabel.text ?? "")"
    }
}
