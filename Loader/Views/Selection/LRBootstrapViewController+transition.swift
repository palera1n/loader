//
//  LRBootstrapViewController+Transition.swift
//  Loader
//
//  Created by samara on 22.03.2025.
//

import UIKit
import NimbleAnimations

// MARK: - Class extension: animations
extension LRBootstrapViewController: UIViewControllerTransitioningDelegate {
	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		SlideWithPresentationAnimator(presenting: true)
	}
	
	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		SlideWithPresentationAnimator(presenting: false)
	}
}
