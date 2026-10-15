import UIKit

/// Builds the app in code (no storyboards): one shared store, the chat list as the root.
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let store = ChatStore(conversations: SampleData.conversations(), replies: CannedReplyService())
        let chats = ConversationsViewController(viewModel: ConversationsViewModel(store: store))
        let navigation = UINavigationController(rootViewController: chats)
        navigation.navigationBar.prefersLargeTitles = true

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = navigation
        window.makeKeyAndVisible()
        self.window = window
    }
}
