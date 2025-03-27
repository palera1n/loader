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
		/// Cell style
		public var style: UITableViewCell.CellStyle = .value1
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
			style: UITableViewCell.CellStyle = .value1,
			tint: UIColor? = nil,
			navigationDestination: UIViewController? = nil,
			presentNavigationDestination: (() -> UINavigationController)? = nil,
			action: (() -> Void)? = nil
		) {
			self.title = title
			self.subtitle = subtitle
			self.style = style
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
		self.setupSections()
	}
	
	open func setupSections() {}
}

// MARK: - Class extension: tableview
extension LRBaseStructuredTableViewController {
	open override func numberOfSections(in tableView: UITableView) -> Int {
		return sections.count
	}
	
	open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return sections[section].items.count
	}
	
	open override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return sections[section].title
	}
	
	open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
			if #available(iOS 15.0, *) {
				cell.textLabel?.textColor = item.tint ?? .tintColor
			}
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
