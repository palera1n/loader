//
//  LRSettingsCreditsViewController.swift
//  Loader
//
//  Created by samara on 9.03.2025.
//

import UIKit
import NimbleExtensions
import NimbleJSON
import NimbleViewControllers

// MARK: - Class
class LRSettingsCreditsViewController: LRBaseTableViewController {
	typealias CreditsDataHandler = Result<CreditsData, Error>
	
	private let _activityIndicator = UIActivityIndicatorView(style: .medium)
	private var _data: [CreditSection] = []
	private let _dataService = FetchService()
	private let _dataURL = URL(string: "https://palera.in/credits.json")!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		title = .localized("Credits")
		
		self._setupActivityIndicator()
		self._load()
	}
	
	private func _setupActivityIndicator() {
		_activityIndicator.hidesWhenStopped = true
		let activityBarButtonItem = UIBarButtonItem(customView: _activityIndicator)
		navigationItem.rightBarButtonItem = activityBarButtonItem
	}
	
	private func _load() {
		_activityIndicator.startAnimating()
		
		_dataService.fetch<CreditsData>(from: _dataURL) { [weak self] (result: CreditsDataHandler) in
			guard let self = self else { return }
			
			DispatchQueue.main.async {
				self._activityIndicator.stopAnimating()
				
				switch result {
				case .success(let data):
					self._data = data.sections
					self.tableView.reloadDataWithTransition(with: .transitionCrossDissolve)
				case .failure(let error):
					self._showError(error.localizedDescription)
				}
			}
		}
	}
	
	private func _showError(_ message: String) {
		let ok = UIAlertAction(title: "OK", style: .cancel) { [weak self] _ in
			self?.navigationController?.popViewController(animated: true)
		}
		
		let retry = UIAlertAction(title: .localized("Retry"), style: .default) { [weak self] _ in
			self?._load()
		}
		
		UIAlertController.showAlert(
			self,
			title: "Error",
			message: message,
			actions: [ok, retry]
		)
	}
}

// MARK: - Class extension: tableview
extension LRSettingsCreditsViewController {
	override func numberOfSections(in tableView: UITableView) -> Int {
		return _data.count
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return _data[section].data.count
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return _data[section].name
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let person = _data[indexPath.section].data[indexPath.row]

		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
		?? UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
		
		cell.textLabel?.text = person.name
		cell.detailTextLabel?.text = "@\(person.github)"
		#if os(iOS)
		cell.detailTextLabel?.textColor = .secondaryLabel
		#endif
		cell.accessoryType = .disclosureIndicator
		
		if let description = person.desc {
			cell.detailTextLabel?.text = cell.detailTextLabel?.text.map {
				"\($0) • \(description)"
			} ?? description
		}
				
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let person = _data[indexPath.section].data[indexPath.row]
		
		self._openProfileURL(for: person)

		tableView.deselectRow(at: indexPath, animated: true)
	}
}

extension LRSettingsCreditsViewController {
	private func _openProfileURL(for person: CreditPerson) {
		if let intent = person.intent,
		   let intentUrl = URL(string: "https://twitter.com/intent/follow?screen_name=\(intent)"),
		   UIApplication.shared.canOpenURL(intentUrl) {
			UIApplication.shared.open(intentUrl)
		} else {
			if let githubUrl = URL(string: "https://github.com/\(person.github)") {
				UIApplication.shared.open(githubUrl)
			}
		}
	}
}
