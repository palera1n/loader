//
//  Bundle+versions.swift
//  Loader
//
//  Created by samara on 18.03.2025.
//

import Foundation.NSBundle

extension Bundle {
	static public var appExecutable: String {
		guard let str = main.object(forInfoDictionaryKey: "CFBundleExecutable") as? String else { return "" }
		return str
	}
	
	static public var appVersionShort: String {
		guard let str = main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else { return "" }
		return str
	}
	
	static public var bundleVersion: String {
		guard let str = main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else { return "" }
		return str
	}
}
