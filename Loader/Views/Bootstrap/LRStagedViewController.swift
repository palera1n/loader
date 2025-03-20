//
//  LRStagedViewController.swift
//  Loader
//
//  Created by samara on 9.03.2025.
//

import UIKit

// MARK: - Class
class LRStagedViewController: LRBaseStagedViewController {
	private var _shouldBootstrap: Bool
	private let _config: LRConfig
	private let _manager: LRManager?
	private var _dataSource: StepDataSource?
	
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
		steps = [
			StepGroup(
				name: "Download",
				items: [
					StepGroupItem(name: "Downloading Package Managers"),
				]
			),
			StepGroup(
				name: "Install",
				items: [
					StepGroupItem(name: "Installing Packages"),
				]
			),
		]
		
		if _shouldBootstrap {
			steps[0].items.insert(StepGroupItem(name: "Downloading Base Bootstrap"), at: 0)
			steps[0].items.insert(StepGroupItem(name: "Downloading Required Packages"), at: 1)
			
			steps.insert(
				StepGroup(
					name: "Bootstrap",
					items: [
						StepGroupItem(name: "Preparing Environment"),
						StepGroupItem(name: "Installing Base Bootstrap"),
						StepGroupItem(name: "Preparing Repositories"),
					]
				),
			at: 1)
		}
	}
	
	override func start() {
		Task.detached {
			try? await Task.sleep(nanoseconds: 1_000_000)
			
			await MainActor.run {
				self.selectCollectionViewCell(for: 0)
			}
			
			let bootstrapper = await LRBootstrapper(
				callback: self,
				config: self._config,
				manager: self._manager,
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
						title: "Error",
						message: error.localizedDescription,
						actions: []
					)
					#else
					print(error)
					#endif
				}
			}
		}
	}
}

extension UICollectionViewDiffableDataSource {
    func refresh(completion: (() -> Void)? = nil) {
        self.apply(self.snapshot(), animatingDifferences: true, completion: completion)
    }
}
