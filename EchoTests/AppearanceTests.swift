import UIKit
import XCTest
@testable import Echo

@MainActor
final class AppearanceTests: XCTestCase {
    private var defaults: UserDefaults!
    private var applied: [UIUserInterfaceStyle] = []

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "AppearanceTests")
        defaults.removePersistentDomain(forName: "AppearanceTests")
        applied = []
    }

    private func makeStore() -> AppearanceStore {
        AppearanceStore(defaults: defaults) { [weak self] style in self?.applied.append(style) }
    }

    func testSystemIsTheDefault() {
        let store = makeStore()
        XCTAssertEqual(store.current, .system)

        store.applySaved()
        XCTAssertEqual(applied, [.unspecified])
    }

    func testChoiceIsAppliedAndRemembered() {
        makeStore().select(.dark)
        XCTAssertEqual(applied, [.dark])

        // A new launch reads the saved choice.
        let relaunched = makeStore()
        XCTAssertEqual(relaunched.current, .dark)
        relaunched.applySaved()
        XCTAssertEqual(applied, [.dark, .dark])
    }

    func testEveryOptionMapsToAStyle() {
        XCTAssertEqual(Appearance.allCases.map(\.title), ["System", "Light", "Dark"])
        XCTAssertEqual(Appearance.allCases.map(\.interfaceStyle), [.unspecified, .light, .dark])
        // Stored in UserDefaults: renaming a case must not lose the user's choice.
        XCTAssertEqual(Appearance.allCases.map(\.rawValue), ["system", "light", "dark"])
    }
}
