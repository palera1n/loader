//
//  LREnvironment+reset.swift
//  Loader
//
//  Created by samara on 18.03.2025.
//

import UIKit.UIDevice

// MARK: - Class extension: reset
extension LREnvironment {
	/// Change sudo password
	/// - Parameter password: The sudo password you want to use
	func resetSudoPassword(with password: String) {
		let dashCommand = "printf \"%s\\n\" \"\(password)\" | \(self.jb_prefix("/usr/sbin/pw")) usermod 501 -h 0"
		Self.execute(.jb_prefix("/usr/bin/dash"), ["-c", dashCommand])
	}
	/// Removes bootstrap
	func removeBootstrap() {
		if
			#available(iOS 18, *),
			UIDevice.current.palera1n.palerain_option_rootless
		{
			let apps = try? FileManager.default.contentsOfDirectory(atPath: .jb_prefix("/Applications"))
			
			if let apps { for app in apps {
				Self.execute(.binpack("/usr/bin/uicache"), ["-u", app])
			}}
		}
		
		guard
			jbd.obliterateJailbreak(cleanFakeFS: UIDevice.current.palera1n.shouldCleanFakefs) == 0
		else {
			return
		}
		
		jbd.reloadLaunchdJailbreakEnvironment()
		
		#if !DEBUG
		reboot()
		#else
		exit(0)
		#endif
	}
	/// Reboots device
	func reboot() {
		Self.execute(.binpack("/bin/launchctl"), ["reboot"])
	}
	/// Reboots userspace
	func rebootUserspace() {
		Self.execute(.binpack("/bin/launchctl"), ["reboot", "userspace"])
	}
	/// UICache
	func uicacheAll() {
		Self.execute(.binpack("/usr/bin/uicache"), ["-a"])
	}
	/// Restart springboard
	func respring() {
		Self.execute(.binpack("/bin/launchctl"), ["kickstart", "-k", "system/com.apple.backboardd"])
	}
	/// Enter device into recovery, then reboot
	func enterRecovery() {
		_ = Self.nvram("auto-boot", "false")
		reboot()
	}
}
