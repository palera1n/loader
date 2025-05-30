//
//  UIDevice+Jailbreak.swift
//  Packages
//
//  Created by samara on 23.02.2025.
//

import UIKit.UIDevice

extension UIDevice {
	struct Flags {
		/// User specified `rootful`
		var palerain_option_rootful: Bool
		/// User specified `rootless`
		var palerain_option_rootless: Bool
		/// System has signed system volum
		var palerain_option_ssv: Bool
		/// User specified `remove jailbreak`
		var palerain_option_force_revert: Bool
		/// User specified `safemode`
		var palerain_option_safemode: Bool
		/// If user has happened to have an rsod
		var palerain_option_failure: Bool
		
		/// See flags in string format
		var flags: String {
			String(format: "0x%llx", LREnvironment.jbd.getFlags())
		}
		/// See flags in a string-list format
		var flagsList: String {
			let mirror = Mirror(reflecting: self)
			let properties = mirror.children.filter { $0.value is Bool }
			
			return "Flags: \(flags)\n\n" + properties.map { label, value in
				"\(label ?? "unknown"): \(value as? Bool ?? false)"
			}.joined(separator: "\n")
		}
		/// In some scenerios where the user would want to revert the jailbreak in-app
		/// there are cases where we cannot remove the entire jailbreak through this.
		/// Mainly, `rootful + ssv ((partial) fakefs)`, so we offer to
		/// revert the snapshot (and some files in the user partition) only on these installs.
		var shouldCleanFakefs: Bool {
			palerain_option_ssv && palerain_option_rootful
		}
		
		init() {
			let flags = LREnvironment.jbd.getFlags();
			self.palerain_option_rootful = (flags & (1 << 0)) != 0
			self.palerain_option_rootless = (flags & (1 << 1)) != 0
			self.palerain_option_ssv = (flags & (1 << 7)) != 0
			self.palerain_option_force_revert = (flags & (1 << 24)) != 0
			self.palerain_option_safemode = (flags & (1 << 25)) != 0
			self.palerain_option_failure = (flags & (1 << 60)) != 0
		}
	}
	
	var palera1n: Flags {
		Flags()
	}
}
