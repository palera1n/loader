//
//  BaseTableViewController.swift
//  Loader
//
//  Created by samara on 9.03.2025.
//


import UIKit

// MARK: - Class
public class LRBaseTableViewController: UITableViewController {
	public init() {
		#if os(iOS)
		super.init(style: .insetGrouped)
		#else
		super.init(style: .grouped)
		#endif
	}
	
	required init?(coder: NSCoder) {
		#if os(iOS)
		super.init(style: .insetGrouped)
		#else
		super.init(style: .grouped)
		#endif
	}
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		#if os(iOS)
		self.configureTitleDisplayMode()
		#endif
	}
	#if os(iOS)
	private func configureTitleDisplayMode() {
		if isRootViewController() {
			navigationItem.largeTitleDisplayMode = .always
			navigationController?.navigationBar.prefersLargeTitles = true
		} else {
			navigationItem.largeTitleDisplayMode = .never
		}
	}
	
	private func isRootViewController() -> Bool {
		return navigationController?.viewControllers.first === self
	}
	#endif
	@objc public func dismissController() {
		dismiss(animated: true)
	}
	
	@objc public func popController() {
		navigationController?.popViewController(animated: true)
	}
}
