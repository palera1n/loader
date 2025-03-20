//
//  TabbarController.swift
//  Loader
//
//  Created by samara on 9.03.2025.
//

import UIKit
import SwiftUI

class LRTabbarController: UITabBarController {
	override func viewDidLoad() {
		super.viewDidLoad()
		self._setupTabs()
	}
	
	private func _setupTabs() {
		let sources = self._createNavigation(
			with: "palera1n",
			and: UIImage(systemName: "wand.and.stars"),
			vc: LRBootstrapViewController()
		)
		
		let apps = self._createNavigation(
			with: .localized("Settings"),
			and: UIImage(systemName: "gear"),
			vc: LRSettingsViewController()
		)
		
		self.setViewControllers([
			sources,
			apps,
		], animated: false)
	}
	
	private func _createNavigation(with title: String, and image: UIImage?, vc: UIViewController) -> UINavigationController {
		let nav = UINavigationController(rootViewController: vc)
		
		nav.tabBarItem.title = title
		nav.tabBarItem.image = image
		nav.viewControllers.first?.navigationItem.title = title
		
		return nav
	}
}
