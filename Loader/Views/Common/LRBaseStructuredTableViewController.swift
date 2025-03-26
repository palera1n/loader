//
//  LRBaseStructuredTableViewController.swift
//  Loader
//
//  Created by samara on 13.03.2025.
//

import UIKit

// MARK: - Class
class LRBaseStructuredTableViewController: LRBaseTableViewController {
	/// An item to a section
	struct SectionItem {
		/// Cell title
		let title: String
		/// Cell subtitle
		var subtitle: String = ""
		/// Cell style
		var style: UITableViewCell.CellStyle = .value1
		/// Cell tint
		var tint: UIColor?
		/// Navigation link, may conflict with `action`
		var navigationDestination: UIViewController? = nil
		/// Present new navigation controller
		var presentNavigationDestination: (() -> UINavigationController)? = nil
		/// Cell action without a navigation destination, may conflict with `navigationDestination`
		var action: (() -> Void)? = nil
	}
	
	/// The tableview will use data from here
	var sections: [(title: String, items: [SectionItem])] = []
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.setupSections()
	}
	
	func setupSections() {}
}

// MARK: - Class extension: tableview
extension LRBaseStructuredTableViewController {
	override func numberOfSections(in tableView: UITableView) -> Int {
		return sections.count
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sections[section].items.count
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return sections[section].title
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let section = sections[indexPath.section]
		let item = section.items[indexPath.row]
		
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
		?? UITableViewCell(style: item.style, reuseIdentifier: "Cell")
		
		cell.textLabel?.text = item.title
		cell.textLabel?.textColor = .label
		cell.detailTextLabel?.text = item.subtitle
		cell.detailTextLabel?.textColor = .secondaryLabel
		cell.detailTextLabel?.numberOfLines = 0
		
		if item.style == .subtitle {
			#if os(iOS)
			cell.detailTextLabel?.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
			#else
			cell.detailTextLabel?.font = .monospacedSystemFont(ofSize: 24, weight: .regular)
			#endif
		}
		
		if (item.navigationDestination != nil) ||
			(item.presentNavigationDestination != nil) {
			cell.accessoryType = .disclosureIndicator
			cell.selectionStyle = .default
		} else if (item.action != nil) {
			#if os(iOS)
			cell.textLabel?.textColor = item.tint ?? .tintColor
			#else
			cell.textLabel?.textColor = item.tint ?? .systemBlue
			#endif
			cell.accessoryType = .none
			cell.selectionStyle = .default
		} else {
			cell.accessoryType = .none
			cell.selectionStyle = .none
		}
		
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let section = sections[indexPath.section]
		let item = section.items[indexPath.row]
		
		if let destinationVC = item.navigationDestination {
			navigationController?.pushViewController(destinationVC, animated: true)
		} else if let destinationVC = item.presentNavigationDestination {
			present(destinationVC(), animated: true)
		} else if let action = item.action {
			action()
		}
		
		tableView.deselectRow(at: indexPath, animated: true)
	}
}

extension LRBaseStructuredTableViewController {
	@discardableResult
	func addUserDefaultsStringSection(
		key: String,
		defaultValue: String,
		sectionTitle: String,
		changeTitle: String = "",
		sectionIndex: Int? = nil,
		keyboardType: UIKeyboardType = .default
	) -> String {
		let userDefaults = UserDefaults.standard
		let currentValue = userDefaults.string(forKey: key) ?? defaultValue
		let isModified = currentValue != defaultValue
		
		var sectionItems: [SectionItem] = []
		
		if isModified {
			sectionItems = [
				SectionItem(
					title: currentValue,
					style: .subtitle,
					tint: .secondaryLabel,
					action: { [weak self] in
						UIAlertController.showAlertForStringChange(
							self!,
							title: changeTitle,
							currentValue: currentValue,
							keyboardType: keyboardType,
							completion: { newValue in
								userDefaults.set(newValue, forKey: key)
								self?.setupSections()
								self?.tableView.reloadData()
							}
						)
					}
				),
				SectionItem(
					title: .localized("Reset Configuration"),
					style: .subtitle,
					tint: .systemRed,
					action: { [weak self] in
						userDefaults.removeObject(forKey: key)
						self?.setupSections()
						self?.tableView.reloadData()
					}
				)
			]
		} else {
			sectionItems = [
				SectionItem(
					title: changeTitle,
					style: .value1,
					tint: .tintColor,
					action: { [weak self] in
						UIAlertController.showAlertForStringChange(
							self!, title: changeTitle,
							currentValue: currentValue,
							keyboardType: keyboardType,
							completion: { newValue in
								userDefaults.set(newValue, forKey: key)
								self?.setupSections()
								self?.tableView.reloadData()
							}
						)
					}
				)
			]
		}
		
		let newSection = (title: sectionTitle, items: sectionItems)
		
		if let index = sectionIndex {
			if sections.count > index {
				sections.insert(newSection, at: index)
			} else {
				sections.append(newSection)
			}
		} else {
			sections.append(newSection)
		}
		
		return currentValue
	}
}
