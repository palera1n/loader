//
//  LREnvironment.swift
//  Loader
//
//  Created by samara on 13.03.2025.
//

import UIKit.UIDevice

// MARK: - Class
class LREnvironment {
	typealias jbd = JailbreakD
	static let shared = LREnvironment()
	
	// MARK: Boostrap status
	
	enum LRBootstrapStatus {
		case bootstrapped
		case partial_bootstrapped_rootless
		case not_bootstrapped
		
		var stringValue: String {
			switch self {
			case .bootstrapped:						"✓"
			case .partial_bootstrapped_rootless:	"!"
			case .not_bootstrapped:					"✗"
			}
		}
	}
	
	/// Devices bootstrap status
	var isBootstrapped: LRBootstrapStatus {
		#if !targetEnvironment(simulator)
		let fileManager = FileManager.default
		let dotfile = dotfilePath()
		
		if fileManager.fileExists(atPath: .jb_prefix(dotfile)) {
			return .bootstrapped
		}
		
		if UIDevice.current.palera1n.palerain_option_rootless {
			if let preboot_path = jbd.getPrebootPath() {
				if fileManager.fileExists(atPath: preboot_path + dotfile) {
					return .partial_bootstrapped_rootless
				}
			}
		}
		#endif
		return .not_bootstrapped
	}
	
	static func default_config_url() -> String {
		"https://\(loaderConfigURL())"
	}
	
	static func config_url() -> String {
		let userDefaults = UserDefaults.standard
		let defaultValue = self.default_config_url()
		let installPath = userDefaults.string(forKey: "defaultInstallPath") ?? defaultValue
		return installPath
	}
}
