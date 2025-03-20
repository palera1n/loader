//
//  UITableView+transition.swift
//  Loader
//
//  Created by samara on 9.03.2025.
//

import UIKit.UITableView
import UIKit.UIView

extension UITableView {
	public func reloadDataWithTransition(
		with animation: UIView.AnimationOptions = [],
		duration: TimeInterval = 0.3
	) {
		UIView.transition(
			with: self,
			duration: duration,
			options: animation,
			animations: { [weak self] in
			self?.reloadData()
		}, completion: nil)
	}
}
