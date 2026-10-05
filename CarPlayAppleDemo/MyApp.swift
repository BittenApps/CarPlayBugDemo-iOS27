import SwiftUI

#if os(iOS)
import CarPlay
import UIKit

@main
final class CarPlayAppDelegate: UIResponder, UIApplicationDelegate {
    private var phoneWindows: [String: UIWindow] = [:]

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Also handle restored phone scenes that arrive without a window from their delegate.
        NotificationCenter.default.addObserver(self, selector: #selector(phoneSceneConnected(_:)),
                                               name: UIScene.willConnectNotification, object: nil)
        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        if connectingSceneSession.role == .carTemplateApplication
            || connectingSceneSession.role.rawValue == "CPTemplateApplicationSceneSessionRoleApplication" {
            configuration.sceneClass = CPTemplateApplicationScene.self
            configuration.delegateClass = CarPlayReproSceneDelegate.self
        } else {
            configuration.sceneClass = UIWindowScene.self
            configuration.delegateClass = PhoneSceneDelegate.self
        }
        return configuration
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        for case let scene as UIWindowScene in application.connectedScenes {
            installPhoneWindowIfNeeded(in: scene)
        }
    }

    @objc private func phoneSceneConnected(_ notification: Notification) {
        guard let scene = notification.object as? UIWindowScene else { return }
        // Let the configured scene delegate create its window first when it is called.
        DispatchQueue.main.async { [weak self, weak scene] in
            guard let scene else { return }
            self?.installPhoneWindowIfNeeded(in: scene)
        }
    }

    private func installPhoneWindowIfNeeded(in scene: UIWindowScene) {
        guard scene.session.role == .windowApplication,
              !scene.windows.contains(where: { $0.rootViewController is UIHostingController<ContentView> }) else { return }
        let window = UIWindow(windowScene: scene)
        window.rootViewController = UIHostingController(rootView: ContentView())
        phoneWindows[scene.session.persistentIdentifier] = window
        window.makeKeyAndVisible()
        print("Installed iPhone sample window for scene \(scene.session.persistentIdentifier)")
    }
}

final class PhoneSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: ContentView())
        self.window = window
        window.makeKeyAndVisible()
    }
}
#else
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
#endif
