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
			using: UIImage(systemName: "wand.and.stars"),
			controller: LRBootstrapViewController()
		)
		
		let apps = self._createNavigation(
			with: .localized("Settings"),
			using: UIImage(systemName: "gear"),
			controller: LRSettingsViewController()
		)
		
		self.setViewControllers([
			sources,
			apps,
		], animated: false)
	}
	
	private func _createNavigation(
		with title: String,
		using image: UIImage?,
		controller: UIViewController
	) -> UINavigationController {
		let nav = UINavigationController(rootViewController: controller)
		nav.tabBarItem.title = title
		nav.tabBarItem.image = image
		nav.viewControllers.first?.navigationItem.title = title
		return nav
	}
}
