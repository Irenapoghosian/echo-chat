import UIKit

/// Three pulsing dots in a gray bubble while the contact is "typing".
final class TypingIndicatorCell: UITableViewCell {
    static let reuseID = "TypingIndicatorCell"

    private let bubble = UIView()
    private let dots: [UIView] = (0..<3).map { _ in UIView() }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none

        bubble.backgroundColor = Theme.incomingBubble
        bubble.layer.cornerRadius = Theme.bubbleRadius
        bubble.layer.cornerCurve = .continuous
        bubble.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        bubble.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubble)

        for dot in dots {
            dot.backgroundColor = .secondaryLabel
            dot.layer.cornerRadius = 4
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 8).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 8).isActive = true
        }
        let row = UIStackView(arrangedSubviews: dots)
        row.spacing = 5
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        bubble.addSubview(row)

        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 3),
            bubble.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubble.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            row.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 13),
            row.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -13),
            row.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 14),
            row.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -14),
        ])
        isAccessibilityElement = true
        accessibilityTraits = .updatesFrequently
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func configure(name: String) {
        accessibilityLabel = "\(name) is typing"
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { startAnimating() }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        startAnimating()
    }

    private func startAnimating() {
        let now = CACurrentMediaTime()
        for (index, dot) in dots.enumerated() {
            dot.layer.removeAllAnimations()
            // With Reduce Motion the dots simply stay visible.
            guard !UIAccessibility.isReduceMotionEnabled else { continue }
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 0.25
            pulse.toValue = 1
            pulse.duration = 0.5
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            pulse.beginTime = now + Double(index) * 0.18
            pulse.fillMode = .backwards
            dot.layer.add(pulse, forKey: "pulse")
        }
    }
}
