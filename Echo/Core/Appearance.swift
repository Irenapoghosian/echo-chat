import UIKit

/// The app's color scheme, chosen in Settings: follow the system, or always light or dark.
enum Appearance: String, CaseIterable {
    case system
    case light
    case dark

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Saves the choice and applies it to every window, so sheets and the photo viewer follow too.
@MainActor
final class AppearanceStore {
    static let storageKey = "appearance"

    private let defaults: UserDefaults
    private let apply: (UIUserInterfaceStyle) -> Void

    /// - Parameter apply: Sets the style on the app's windows; tests pass a recorder.
    init(defaults: UserDefaults = .standard, apply: @escaping (UIUserInterfaceStyle) -> Void) {
        self.defaults = defaults
        self.apply = apply
    }

    var current: Appearance {
        defaults.string(forKey: Self.storageKey).flatMap(Appearance.init(rawValue:)) ?? .system
    }

    func select(_ appearance: Appearance) {
        defaults.set(appearance.rawValue, forKey: Self.storageKey)
        apply(appearance.interfaceStyle)
    }

    /// Call once at launch, before the first screen appears.
    func applySaved() {
        apply(current.interfaceStyle)
    }
}
