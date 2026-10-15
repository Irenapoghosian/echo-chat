import UIKit

/// Avatar, name, time and a two-line preview, like Messages.
final class ConversationCell: UITableViewCell {
    static let reuseID = "ConversationCell"

    private let avatar = AvatarView()
    private let nameLabel = UILabel()
    private let timeLabel = UILabel()
    private let previewLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator

        nameLabel.font = Theme.font(.headline, weight: .semibold)
        timeLabel.font = Theme.font(.footnote)
        timeLabel.textColor = .secondaryLabel
        previewLabel.font = Theme.font(.subheadline)
        previewLabel.numberOfLines = 2
        timeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        timeLabel.setContentHuggingPriority(.required, for: .horizontal)
        [nameLabel, timeLabel, previewLabel].forEach { $0.adjustsFontForContentSizeCategory = true }

        let topRow = UIStackView(arrangedSubviews: [nameLabel, timeLabel])
        topRow.spacing = 8
        topRow.alignment = .firstBaseline
        let text = UIStackView(arrangedSubviews: [topRow, previewLabel])
        text.axis = .vertical
        text.spacing = 2

        let row = UIStackView(arrangedSubviews: [avatar, text])
        row.spacing = 12
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(row)

        NSLayoutConstraint.activate([
            avatar.widthAnchor.constraint(equalToConstant: 52),
            avatar.heightAnchor.constraint(equalToConstant: 52),
            row.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            row.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            row.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(with row: ConversationRow) {
        avatar.configure(initials: row.initials, colorIndex: row.colorIndex)
        nameLabel.text = row.name
        timeLabel.text = row.timestamp
        previewLabel.text = row.preview
        previewLabel.textColor = row.isTyping ? .tintColor : .secondaryLabel
        accessibilityLabel = "\(row.name), \(row.preview), \(row.timestamp)"
    }
}
