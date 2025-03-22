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
		LREnvironment.execute(self.jb_prefix("/usr/bin/dash"), ["-c", dashCommand])
	}
	/// Removes bootstrap
	func removeBootstrap() {
		let ret = jbd.obliterateJailbreak(
			revertSnapshot: UIDevice.current.palera1n.canRevertSnapshot
		)
		jbd.reloadLaunchdJailbreakEnvironment()
		
		if ret != 0 {
			return
		}
		
		#if !DEBUG
		reboot()
		#else
		exit(0)
		#endif
	}
	
	func reboot() {
		LREnvironment.execute(.binpack("/bin/launchctl"), ["reboot"])
	}
}
