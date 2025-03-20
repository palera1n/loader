//
//  LRBootstrapViewController.swift
//  Loader
//
//  Created by samara on 9.03.2025.
//

import UIKit
import NimbleAnimations
import NimbleJSON

// MARK: - Class
class LRBootstrapViewController: LRBaseTableViewController {
	typealias LRConfigHandler = Result<LRConfig, Error>
	
	private let _activityIndicator = UIActivityIndicatorView(style: .medium)
	private var _data: LRConfig? = nil
	private let _dataService = FetchService()
	private let _dataURL = URL(string: "https://palera.in/loaderv2.json")!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self._notifyUserIfCertainFlags()
		self._setupActivityIndicator()
		self._load()
		#if os(iOS)
		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(self._load), for: .valueChanged)
		#endif
	}
	
	private func _setupActivityIndicator() {
		_activityIndicator.hidesWhenStopped = true
		let activityBarButtonItem = UIBarButtonItem(customView: _activityIndicator)
		navigationItem.rightBarButtonItem = activityBarButtonItem
	}
	
	@objc private func _load() {
		_activityIndicator.startAnimating()
		#if os(iOS)
		refreshControl?.beginRefreshing()
		#endif
		
		_dataService.fetch<LRConfig>(from: _dataURL) { [weak self] (result: LRConfigHandler) in
			guard let self = self else { return }

			DispatchQueue.main.async {
				self._activityIndicator.stopAnimating()
				#if os(iOS)
				self.refreshControl?.endRefreshing()
				#endif
				
				switch result {
				case .success(let data):
					self._data = data
					self.tableView.reloadDataWithTransition(with: .transitionCrossDissolve, duration: 0.4)
				case .failure(let error):
					self._showError(error.localizedDescription)
				}
			}
		}
	}
	
	#warning("may simplify later")
	private func _notifyUserIfCertainFlags() {
		if UIDevice.current.palera1n.palerain_option_force_revert {
			let rebootAction = UIAlertAction(title: .localized("Reboot"), style: .default) { _ in
				LREnvironment.shared.reboot()
			}
			
			UIAlertController.showAlertWithCancel(
				self,
				title: .localized("You've removed the jailbreak!"),
				message: .localized("Is Force Reverted", arguments: UIDevice.current.marketingModel),
				actions: [rebootAction]
			)
		}
		
		if UIDevice.current.palera1n.palerain_option_failure ||
			UIDevice.current.palera1n.palerain_option_safemode {
			
			let safemodeAction = UIAlertAction(title: .localized("Exit"), style: .default) { _ in
				LREnvironment.jbd.exitFailureSafeMode()
			}
			
			UIAlertController.showAlertWithCancel(
				self,
				title: "Safemode",
				message: .localized("You've entered safemode by either manually or palera1n saved you from it."),
				actions: [safemodeAction]
			)
		}
	}
	
	private func _showError(_ message: String) {
		let retry = UIAlertAction(title: .localized("Retry"), style: .default) { [weak self] _ in
			self?._load()
		}
		
		UIAlertController.showAlertWithCancel(
			self,
			title: "err",
			message: message,
			actions: [retry]
		)
	}
}

// MARK: - Class extension: tableview
extension LRBootstrapViewController {
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return _data?.content()?.managers.count ?? 0
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let manager = _data?.content()?.managers[indexPath.row]
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
		?? UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
		
		cell.textLabel?.text = manager?.name
		cell.accessoryType = .disclosureIndicator
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let manager = _data?.content()?.managers[indexPath.row]
		guard let data = _data, let manager = manager else { return }

		self._showManagerPopup(with: data, using: manager)
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		guard let data = _data else { return nil }
		return data.footer_notice
	}
	
	private func _showManagerPopup(with config: LRConfig, using manager: LRManager) {
		let managerInstalled = FileManager.default.fileExists(atPath: manager.filePath.relativePath)
		
		let alertTitle = managerInstalled
		? String.localized("%@ is already installed.", arguments: manager.name)
		: nil
		
		let installActionTitle = managerInstalled 
		? String.localized("Reinstall %@", arguments: manager.name)
		: String.localized("Install %@", arguments: manager.name)
		
		var actions: [UIAlertAction] = []
		
		if managerInstalled {
			actions.append(UIAlertAction(title: .localized("Open %@", arguments: manager.name), style: .default) { _ in
				UIApplication.shared.openApplication(using: manager.filePath.relativePath)
			})
		}
		
		actions.append(UIAlertAction(title: installActionTitle, style: .default) { _ in
			self._showStagedViewController(with: config, using: manager)
		})
		
		UIAlertController.showAlertWithCancel(
			self,
			title: alertTitle,
			message: nil,
			style: .actionSheet,
			actions: actions
		)
	}
	
	private func _showStagedViewController(with config: LRConfig, using manager: LRManager) {
		let controller = LRStagedViewController(
			title: "Installing",
			config: config,
			manager: manager,
			shouldBootstrap: LREnvironment.shared.isBootstrapped == .not_bootstrapped
		)

		let nav = UINavigationController(rootViewController: controller)
		nav.modalPresentationStyle = .custom
		nav.transitioningDelegate = self
		present(nav, animated: true)
	}
}

// MARK: - Class extension: animations
extension LRBootstrapViewController: UIViewControllerTransitioningDelegate {
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		SlideWithPresentationAnimator(presenting: true)
	}
	
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		SlideWithPresentationAnimator(presenting: false)
	}
}
