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

// MARK: - Class extension: model
extension LRSettingsCreditsViewController {
	struct CreditSection: Decodable {
		let name: String
		let data: [CreditPerson]
		
		struct CreditPerson: Decodable {
			let name: String
			let github: String
			let intent: String?
			let desc: String?
		}
	}
	
	struct CreditsData: Decodable {
		let sections: [CreditSection]
	}
}

// MARK: - Class
class LRSettingsCreditsViewController: LRBaseTableViewController {
	typealias CreditsDataHandler = Result<CreditsData, Error>
	
	private let _activityIndicator = UIActivityIndicatorView(style: .medium)
	private var _data: [CreditSection] = []
	private let _dataService = FetchService()
	private let _dataURL = URL(string: "https://palera.in/credits.json")!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		_setupNavigation()
		_load()
	}
	
	private func _setupNavigation() {
		title = .localized("Credits")
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
			title: ":(",
			message: message,
			actions: [ok, retry]
		)
	}
}

// MARK: - Class extension: tableview
extension LRSettingsCreditsViewController {
	override func numberOfSections(in tableView: UITableView) -> Int {
		_data.count
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		_data[section].data.count
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		_data[section].name
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
		let person = _data[indexPath.section].data[indexPath.row]
		
		cell.accessoryType = .disclosureIndicator
		
		var content = cell.defaultContentConfiguration()
		content.text = person.name
		content.secondaryText = "@\(person.github)"
		content.secondaryTextProperties.color = .secondaryLabel
		
		if let description = person.desc {
			content.secondaryText = cell.detailTextLabel?.text.map {
				"\($0) • \(description)"
			} ?? description
		}
		
		cell.contentConfiguration = content
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let person = _data[indexPath.section].data[indexPath.row]
		self._openProfileURL(for: person)
		tableView.deselectRow(at: indexPath, animated: true)
	}
}

// MARK: - Class extension: Open
extension LRSettingsCreditsViewController {
	private func _openProfileURL(for person: CreditSection.CreditPerson) {
		if
			let intent = person.intent,
			let intentUrl = URL(string: "https://twitter.com/intent/follow?screen_name=\(intent)"),
			UIApplication.shared.canOpenURL(intentUrl) 
		{
			UIApplication.shared.open(intentUrl)
		} else if let githubUrl = URL(string: "https://github.com/\(person.github)") {
			UIApplication.shared.open(githubUrl)
		}
	}
}
