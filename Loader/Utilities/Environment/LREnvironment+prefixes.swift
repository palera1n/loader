//
//  LREnvironment+prefixes.swift
//  Loader
//
//  Created by samara on 18.03.2025.
//

import UIKit.UIDevice

// MARK: - Class extension: prefixes
extension LREnvironment {
	func jb_prefix(_ path: String) -> String {
		#if !targetEnvironment(simulator)
		if UIDevice.current.palera1n.palerain_option_rootless {
			return "/var/jb" + path
		}
		#endif
		
		return path
	}
	
	static func binpack(_ path: String) -> String {
		return "/cores/binpack" + path
	}
	
	static func tmp(_ path: String = "") -> String {
		return "/tmp/palera1n" + path
	}
}
