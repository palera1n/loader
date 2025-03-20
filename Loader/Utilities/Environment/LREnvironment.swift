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
	
	enum bootstrapStatus {
		case bootstrapped
		case partial_bootstrapped_rootless
		case not_bootstrapped
	}
	
	/// Devices bootstrap status
	var isBootstrapped: bootstrapStatus {
		#if !targetEnvironment(simulator)
		let fileManager = FileManager.default
		let dotfile = "/.installed_palera1n"
		
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
	
}
