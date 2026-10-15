import UIKit

/// Colors and fonts in one place. Everything uses semantic colors, so Dark Mode just works.
enum Theme {
    static let outgoingBubble = UIColor.systemBlue
    static let outgoingText = UIColor.white
    static let incomingBubble = UIColor.secondarySystemBackground
    static let incomingText = UIColor.label
    static let bubbleRadius: CGFloat = 18

    static let avatarColors: [UIColor] = [
        .systemBlue, .systemPink, .systemOrange, .systemTeal, .systemPurple, .systemGreen,
    ]

    static func avatarColor(at index: Int) -> UIColor {
        avatarColors[abs(index) % avatarColors.count]
    }

    /// A Dynamic Type font with an explicit weight.
    static func font(_ style: UIFont.TextStyle, weight: UIFont.Weight = .regular) -> UIFont {
        // Start from the default text size; `scaledFont` then follows the user's setting.
        let defaultSize = UITraitCollection(preferredContentSizeCategory: .large)
        let base = UIFont.preferredFont(forTextStyle: style, compatibleWith: defaultSize)
        let font = UIFont.systemFont(ofSize: base.pointSize, weight: weight)
        return UIFontMetrics(forTextStyle: style).scaledFont(for: font)
    }
}
