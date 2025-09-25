//
//  LRStagedViewController.swift
//  Loader
//
//  Created by samara on 9.03.2025.
//

import UIKit
import NimbleViewControllers

// MARK: - Class
class LRStagedViewController: LRBaseStagedViewController {
	private var _shouldBootstrap: Bool
	private let _config: LRConfig
	private let _manager: LRManager?
	
	init(title: String, config: LRConfig, manager: LRManager? = nil, shouldBootstrap: Bool = true) {
		self._config = config
		self._manager = manager
		self._shouldBootstrap = shouldBootstrap
		super.init()
		self.title = title
	}
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func setupView() {
		footerString = "Do not exit the app during this process, it may lead to unforeseen issues."
		steps = [
			StepGroup(
				name: .localized("Download"),
				items: [
					StepGroupItem(name: .localized("Downloading Package Managers")),
				]
			),
			StepGroup(
				name: .localized("Install"),
				items: [
					StepGroupItem(name: .localized("Installing Packages")),
				]
			),
		]
		
		if _shouldBootstrap {
			steps[0].items.insert(StepGroupItem(name: .localized("Downloading Base Bootstrap")), at: 0)
			steps[0].items.insert(StepGroupItem(name: .localized("Downloading Required Packages")), at: 1)
			
			steps.insert(
				StepGroup(
					name: .localized("Bootstrap"),
					items: [
						StepGroupItem(name: .localized("Preparing Environment")),
						StepGroupItem(name: .localized("Installing Base Bootstrap")),
						StepGroupItem(name: .localized("Preparing Repositories")),
					]
				),
			at: 1)
		}
	}
	
	override func start() {
		if _shouldBootstrap {
			UIAlertController.showAlertForPassword(
				self,
				title: .localized("Set Password"),
				message: .localized("Password Explanation")
			) { password in
				self._proceedInstallation(password: password)
			}
		} else {
			self._proceedInstallation()
		}
	}
	
	private func _proceedInstallation(password: String = "alpine") {
		Task.detached {
			try? await Task.sleep(nanoseconds: 1_000_000)
			
			await MainActor.run {
				self.selectCollectionViewCell(for: 0)
			}
			
			let bootstrapper = await LRBootstrapper(
				callback: self,
				config: self._config,
				manager: self._manager,
				sudo_password: password,
				shouldBootstrap: self._shouldBootstrap
			)
			
			do {
				try await bootstrapper.prepareFiles()
				if await self._shouldBootstrap { try await bootstrapper.bootstrap() }
				try await bootstrapper.installPackages()
			} catch {
				await MainActor.run {
					#if !targetEnvironment(simulator)
					UIAlertController.showAlert(
						self,
						title: "",
						message: "\(error)",
						actions: []
					)
					#else
					print("\(error)")
					#endif
				}
			}
		}
	}
	
}
