import UIKit

/// A quoted message: a colored bar, the author and one line of the message.
/// Used inside reply bubbles and above the composer while replying.
final class QuoteView: UIView {
    private let bar = UIView()
    private let authorLabel = UILabel()
    private let summaryLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        bar.layer.cornerRadius = 1.5
        authorLabel.font = Theme.font(.caption1, weight: .semibold)
        summaryLabel.font = Theme.font(.caption1)
        summaryLabel.numberOfLines = 1
        [authorLabel, summaryLabel].forEach { $0.adjustsFontForContentSizeCategory = true }

        let text = UIStackView(arrangedSubviews: [authorLabel, summaryLabel])
        text.axis = .vertical
        text.spacing = 1
        let row = UIStackView(arrangedSubviews: [bar, text])
        row.spacing = 8
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)

        NSLayoutConstraint.activate([
            bar.widthAnchor.constraint(equalToConstant: 3),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
        isAccessibilityElement = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// - Parameter onBlue: `true` inside my blue bubble, where everything turns white.
    func configure(author: String, summary: String, onBlue: Bool = false) {
        authorLabel.text = author
        summaryLabel.text = summary
        bar.backgroundColor = onBlue ? .white : .tintColor
        authorLabel.textColor = onBlue ? .white : .tintColor
        summaryLabel.textColor = onBlue ? UIColor.white.withAlphaComponent(0.85) : .secondaryLabel
    }
}
