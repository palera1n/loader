//
//  UIApplication+open.swift
//  Loader
//
//  Created by samara on 15.03.2025.
//

import UIKit.UIApplication

extension UIApplication {
	/// Opens an application using `LSApplicationWorkspace` with a relative path
	func openApplication(using relativePath: String) {
		openApplication(at: URL(fileURLWithPath: relativePath))
	}
	/// Opens an application using `LSApplicationWorkspace` with a url file path
	func openApplication(at path: URL) {
		let bundle = Bundle(url: path)
		LSApplicationWorkspace.default().openApplication(withBundleID: bundle?.bundleIdentifier)
	}
}
