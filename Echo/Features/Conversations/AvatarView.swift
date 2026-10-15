import UIKit

/// A colored circle with the contact's initials.
final class AvatarView: UIView {
    private let initialsLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialsLabel.font = Theme.font(.headline, weight: .semibold)
        initialsLabel.adjustsFontForContentSizeCategory = true
        initialsLabel.textColor = .white
        initialsLabel.textAlignment = .center
        initialsLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(initialsLabel)
        NSLayoutConstraint.activate([
            initialsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            initialsLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        isAccessibilityElement = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }

    func configure(initials: String, colorIndex: Int) {
        initialsLabel.text = initials
        backgroundColor = Theme.avatarColor(at: colorIndex)
    }
}
