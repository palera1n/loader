//
//  SceneDelegate.swift
//  Loader
//
//  Created by samara on 9.03.2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
	var window: UIWindow?

	func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
		guard let windowScene = scene as? UIWindowScene else { return }
		
		let window = UIWindow(windowScene: windowScene)
		let controller = LRTabbarController()
		
		#if os(iOS)
		if #available(iOS 15.0, *) {
			window.tintColor = .label
		}
		#endif
		window.rootViewController = controller
		window.makeKeyAndVisible()
		self.window = window
	}
}

