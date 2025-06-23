//
//  LRBaseStructuredTableViewController.swift
//  Loader
//
//  Created by samara on 13.03.2025.
//

import UIKit

// MARK: - Class
open class LRBaseStructuredTableViewController: LRBaseTableViewController {
	/// An item to a section
	public struct SectionItem {
		/// Cell title
		public let title: String
		/// Cell subtitle
		public var subtitle: String = ""
		/// Cell tint
		public var tint: UIColor?
		/// Navigation link, may conflict with `action`
		public var navigationDestination: UIViewController? = nil
		/// Present new navigation controller
		public var presentNavigationDestination: (() -> UINavigationController)? = nil
		/// Cell action without a navigation destination, may conflict with `navigationDestination`
		public var action: (() -> Void)? = nil
		
		/// Public initializer
		public init(
			title: String,
			subtitle: String = "",
			tint: UIColor? = nil,
			navigationDestination: UIViewController? = nil,
			presentNavigationDestination: (() -> UINavigationController)? = nil,
			action: (() -> Void)? = nil
		) {
			self.title = title
			self.subtitle = subtitle
			self.tint = tint
			self.navigationDestination = navigationDestination
			self.presentNavigationDestination = presentNavigationDestination
			self.action = action
		}
	}
	
	/// The tableview will use data from here
	public var sections: [(title: String, items: [SectionItem])] = []
	
	open override func viewDidLoad() {
		super.viewDidLoad()
		setupSections()
	}
	
	open func setupSections() {}
}

// MARK: - Class extension: tableview
extension LRBaseStructuredTableViewController {
	open override func numberOfSections(in tableView: UITableView) -> Int {
		sections.count
	}
	
	open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		sections[section].items.count
	}
	
	open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		sections[section].title
	}
	
	open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
		let section = sections[indexPath.section]
		let item = section.items[indexPath.row]
		
		var content = UIListContentConfiguration.valueCell()
		content.text = item.title
		content.textProperties.color = .label
		content.secondaryText = item.subtitle
		content.secondaryTextProperties.color = .secondaryLabel
		
		if (item.navigationDestination != nil) ||
			(item.presentNavigationDestination != nil) {
			cell.accessoryType = .disclosureIndicator
			cell.selectionStyle = .default
		} else if (item.action != nil) {
			#if os(iOS)
			content.textProperties.color = item.tint ?? .tintColor
			#else
			content.textProperties.color = item.tint ?? .systemBlue
			#endif
			cell.accessoryType = .none
			cell.selectionStyle = .default
		} else {
			cell.accessoryType = .none
			cell.selectionStyle = .none
		}
		
		cell.contentConfiguration = content
		return cell
	}
	
	open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
