//
//  BaseTableViewController.swift
//  Loader
//
//  Created by samara on 9.03.2025.
//

import UIKit
import NimbleExtensions

// MARK: - Class
open class LRBaseTableViewController: UITableViewController {
	private var _didControllerFade = false
	private var _hideStatusBar = false
	
	public init() {
		#if os(iOS)
		super.init(style: .insetGrouped)
		#else
		super.init(style: .grouped)
		#endif
	}
	
	required public init?(coder: NSCoder) {
		#if os(iOS)
		super.init(style: .insetGrouped)
		#else
		super.init(style: .grouped)
		#endif
	}
	
	open override var prefersStatusBarHidden: Bool {
		return self._hideStatusBar
	}
	
	open override func viewDidLoad() {
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
	
	@objc public func blackOutController(completion: @escaping () -> (Void)) {
		if _didControllerFade {
			completion()
			return
		}
		
		self._didControllerFade = true
		
		guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else {
			completion()
			return
		}
		
		guard let snapshotView = window.snapshotView(afterScreenUpdates: true) else {
			completion()
			return
		}
		
		window.addSubview(snapshotView)
		snapshotView.frame = window.bounds
		
		snapshotView.layer.cornerRadius = UIScreen.main.screenCornerRadius
		snapshotView.layer.cornerCurve = .continuous
		snapshotView.layer.masksToBounds = true
		
		for subview in window.subviews where subview != snapshotView {
			subview.alpha = 0
		}
		
		self._setHideStatusBar(true)
		
		let animator = UIViewPropertyAnimator(
			duration: 0.45,
			dampingRatio: 0.9
		) {
			snapshotView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
			snapshotView.alpha = 0.0
		}
		
		animator.addCompletion { position in
			if position == .end {
				snapshotView.removeFromSuperview()
				completion()
			}
		}
		
		animator.startAnimation()
	}
	
	private func _setHideStatusBar(_ bool: Bool) {
		self._hideStatusBar = bool
		self.setNeedsStatusBarAppearanceUpdate()
	}
}
