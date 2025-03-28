//
//  LRBootstrapViewController.swift
//  Loader
//
//  Created by samara on 9.03.2025.
//

import UIKit
import NimbleJSON
import NimbleViewControllers

// MARK: - Class
class LRBootstrapViewController: LRBaseTableViewController {
	typealias LRConfigHandler = Result<LRConfig, Error>
	
	private let _activityIndicator = UIActivityIndicatorView(style: .medium)
	private var _data: LRConfig? = nil
	private let _dataService = FetchService()
	private let _dataURL = URL(string: LREnvironment.config_url())!
	
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
	
	private func _notifyUserIfCertainFlags() {
		var alertConfig: (title: String, message: String, buttonTitle: String, action: (() -> Void)?)?
		
		switch true {
		case UIDevice.current.palera1n.palerain_option_force_revert:
			alertConfig = (
				title: .localized("You've removed the jailbreak!"),
				message: .localized("Is Force Reverted", arguments: UIDevice.current.marketingModel),
				buttonTitle: .localized("Reboot"),
				action: {
					self.blackOutController {
						LREnvironment.shared.reboot()
					}
				}
			)
		case UIDevice.current.palera1n.palerain_option_failure || UIDevice.current.palera1n.palerain_option_safemode:
			alertConfig = (
				title: "",
				message: .localized("You've entered safemode by either manually or palera1n saved you from it."),
				buttonTitle: .localized("Exit"),
				action: {
					self.blackOutController {
						LREnvironment.jbd.exitFailureSafeMode()
					}
				}
			)
		case LREnvironment.shared.isBootstrapped == .partial_bootstrapped_rootless:
			alertConfig = (
				title: "",
				message: .localized("Detected partial rootless installation. Please re-jailbreak and try again."),
				buttonTitle: .localized("Reboot"),
				action: {
					self.blackOutController {
						LREnvironment.shared.reboot()
					}
				}
			)
		default:
			return
		}
		
		if let config = alertConfig {
			let action = UIAlertAction(title: config.buttonTitle, style: .default) { _ in
				config.action?()
			}
			
			UIAlertController.showAlertWithCancel(
				self,
				title: config.title,
				message: config.message,
				actions: [action]
			)
		}
	}
	
	private func _showError(_ message: String) {
		let retry = UIAlertAction(title: .localized("Retry"), style: .default) { [weak self] _ in
			self?._load()
		}
		
		UIAlertController.showAlertWithCancel(
			self,
			title: "",
			message: message,
			actions: [retry]
		)
	}
}

// MARK: - Class extension: tableview
extension LRBootstrapViewController {
	override func numberOfSections(in tableView: UITableView) -> Int {
		1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		_data?.content()?.managers.count ?? 0
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

		self._showManagerPopup(
			with: data,
			using: manager,
			popoverUIView: tableView.cellForRow(at: indexPath)!
		)
		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		_data?.footer_notice ?? nil
	}
}

// MARK: - Class extension: actions
extension LRBootstrapViewController {
	private func _showManagerPopup(
		with config: LRConfig,
		using manager: LRManager,
		popoverUIView: UIView? = nil
	) {
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
			popoverUIView,
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
