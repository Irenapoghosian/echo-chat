import UIKit

/// Builds the app in code (no storyboards): one shared store, the chat list as the root.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Saved chats survive relaunches. If the database can't open, the app still runs in memory.
        let persistence = try? CoreDataChatPersistence()
        let store = ChatStore(
            conversations: ChatBootstrap.conversations(from: persistence),
            replies: CannedReplyService(),
            persistence: persistence
        )
        // Light or Dark from Settings is set on the window, so every screen and sheet follows it.
        let appearance = AppearanceStore { [weak windowScene] style in
            windowScene?.windows.forEach { $0.overrideUserInterfaceStyle = style }
        }
        let chats = ConversationsViewController(viewModel: ConversationsViewModel(store: store), appearance: appearance)
        let navigation = UINavigationController(rootViewController: chats)
        navigation.navigationBar.prefersLargeTitles = true

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        self.window = window
        appearance.applySaved()
    }
}
