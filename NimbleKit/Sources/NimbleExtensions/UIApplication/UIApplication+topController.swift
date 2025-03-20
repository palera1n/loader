//
//  UIApplication+topController.swift
//  Loader
//
//  Created by samara on 18.03.2025.
//

import UIKit.UIApplication

extension UIApplication {
	public class func getTopViewController(
		base: UIViewController? = UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
) -> UIViewController? {
		if let nav = base as? UINavigationController {
			return getTopViewController(base: nav.visibleViewController)
			
		} else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
			return getTopViewController(base: selected)
			
		} else if let presented = base?.presentedViewController {
			return getTopViewController(base: presented)
		}
	
		return base
	}
}
