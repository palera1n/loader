//
//  String+localized.swift
//  NimbleKit
//
//  Created by samara on 20.03.2025.
//


import Foundation

extension String {
	static public func localized(_ name: String) -> String {
		return NSLocalizedString(name, comment: "")
	}
	
	static public func localized(_ name: String, arguments: CVarArg...) -> String {
		return String(format: NSLocalizedString(name, comment: ""), arguments: arguments)
	}
	/// Localizes the current string using the main bundle.
	///
	/// - Returns: The localized string.
	public func localized() -> String {
		return String.localized(self)
	}
}
