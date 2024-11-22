import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let vc = MainViewController()
        let window = UIWindow(windowScene: windowScene)
        window.makeKeyAndVisible()
        let navController = UINavigationController(rootViewController: vc)
        window.rootViewController = navController
        self.window = window
    }
}
