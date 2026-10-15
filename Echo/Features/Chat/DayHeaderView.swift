import UIKit

/// "Today", "Yesterday"… in a small pill between days.
final class DayHeaderView: UITableViewHeaderFooterView {
    static let reuseID = "DayHeaderView"

    private let label = PaddedLabel()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        var background = UIBackgroundConfiguration.clear()
        background.backgroundColor = .clear
        backgroundConfiguration = background

        label.font = Theme.font(.caption1, weight: .semibold)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        label.backgroundColor = .tertiarySystemFill
        label.layer.cornerRadius = 10
        label.layer.cornerCurve = .continuous
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.accessibilityTraits = .header
        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(title: String) {
        label.text = title
    }
}

/// A label with room around its text, for pills and badges.
final class PaddedLabel: UILabel {
    var insets = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: insets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + insets.left + insets.right, height: size.height + insets.top + insets.bottom)
    }
}
