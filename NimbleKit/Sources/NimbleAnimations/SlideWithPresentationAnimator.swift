//
//  SlideWithPresentationAnimator.swift
//  Loader
//
//  Created by samara on 9.03.2025.
//

import UIKit
import NimbleExtensions

public class SlideWithPresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
	private let _presenting: Bool
	
	public init(presenting: Bool) {
		self._presenting = presenting
		super.init()
	}
	
	public func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
		return 0.8
	}
	
	public func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
		let containerView = transitionContext.containerView
		
		guard let toVC = transitionContext.viewController(forKey: .to),
			  let fromVC = transitionContext.viewController(forKey: .from),
			  let toView = transitionContext.view(forKey: .to) ?? toVC.view,
			  let fromView = transitionContext.view(forKey: .from) ?? fromVC.view else {
			transitionContext.completeTransition(false)
			return
		}
		
		let finalFrame = transitionContext.finalFrame(for: toVC)
		
		let displayCornerRadius = UIScreen.main.screenCornerRadius
		
		let startingCornerRadius: CGFloat = 20.0
		
		#if os(iOS)
		let generator = UIImpactFeedbackGenerator(style: .soft)
		generator.prepare()
		#endif
		
		let fromViewLayer = fromView.layer
		let toViewLayer = toView.layer
		
		fromViewLayer.masksToBounds = true
		toViewLayer.masksToBounds = true
		
		if _presenting {
			containerView.addSubview(toView)
			
			toView.frame = finalFrame
			toView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
			toView.center = CGPoint(x: containerView.center.x,
									y: containerView.bounds.height + finalFrame.height/2)
			
			fromViewLayer.cornerRadius = displayCornerRadius
			toViewLayer.cornerRadius = startingCornerRadius
			
			fromViewLayer.cornerCurve = .continuous
			toViewLayer.cornerCurve = .continuous
			
			let fromCornerAnimation = CABasicAnimation(keyPath: "cornerRadius")
			fromCornerAnimation.fromValue = displayCornerRadius
			fromCornerAnimation.toValue = startingCornerRadius
			fromCornerAnimation.duration = transitionDuration(using: transitionContext) * 0.5
			fromCornerAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
			fromViewLayer.add(fromCornerAnimation, forKey: "cornerRadius")
			fromViewLayer.cornerRadius = startingCornerRadius
			
			let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext),
												  dampingRatio: 0.85) {
				fromView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
				fromView.alpha = 0.5
				
				fromView.center = CGPoint(x: containerView.center.x,
										  y: -finalFrame.height/2)
				
				toView.center = containerView.center
				toView.transform = .identity
				toView.alpha = 1.0
				toViewLayer.cornerRadius = displayCornerRadius
				#if os(iOS)
				generator.impactOccurred()
				#endif
			}
			
			animator.addCompletion { position in
				if position == .end {
					transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
				}
			}
			
			animator.startAnimation()
		} else {
			if toView.superview == nil {
				containerView.insertSubview(toView, belowSubview: fromView)
				toView.frame = finalFrame
				toView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
				toView.alpha = 0.5
				toView.center = CGPoint(x: containerView.center.x,
										y: -finalFrame.height/2)
			}
			
			fromViewLayer.cornerRadius = displayCornerRadius
			toViewLayer.cornerRadius = startingCornerRadius
			
			fromViewLayer.cornerCurve = .continuous
			toViewLayer.cornerCurve = .continuous
			
			let fromCornerAnimation = CABasicAnimation(keyPath: "cornerRadius")
			fromCornerAnimation.fromValue = displayCornerRadius
			fromCornerAnimation.toValue = startingCornerRadius
			fromCornerAnimation.duration = transitionDuration(using: transitionContext) * 0.5
			fromCornerAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
			fromViewLayer.add(fromCornerAnimation, forKey: "cornerRadius")
			fromViewLayer.cornerRadius = startingCornerRadius
			
			let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext),
												  dampingRatio: 0.85) {
				fromView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
				fromView.alpha = 0.5
				
				fromView.center = CGPoint(x: containerView.center.x,
										  y: containerView.bounds.height + finalFrame.height/2)
				
				toView.center = containerView.center
				toView.transform = .identity
				toView.alpha = 1.0
				toViewLayer.cornerRadius = displayCornerRadius
				#if os(iOS)
				generator.impactOccurred()
				#endif
			}
			
			animator.addCompletion { position in
				if position == .end {
					transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
				}
			}
			
			animator.startAnimation()
		}
	}
}
