//
//  UIDevice+Jailbreak.swift
//  Packages
//
//  Created by samara on 23.02.2025.
//

import UIKit.UIDevice

extension UIDevice {
	struct Flags {
		var palerain_option_rootful:				Bool
		var palerain_option_rootless:				Bool
		var palerain_option_setup_rootful:			Bool
		// reserved
		var palerain_option_setup_partial_root:		Bool
		var palerain_option_checkrain_is_clone:		Bool
		var palerain_option_rootless_livefs:		Bool
		var palerain_option_ssv:					Bool
//		var palerain_option_force_fakefs:			Bool
		var palerain_option_clean_fakefs:			Bool
		var palerain_option_tui:					Bool
		var palerain_option_gui:					Bool
		var palerain_option_dfuhelper_only:			Bool
		var palerain_option_pongo_exit:				Bool
		var palerain_option_demote:					Bool
		var palerain_option_pongo_full:				Bool
		var palerain_option_palerain_version:		Bool
		var palerain_option_exit_recovery:			Bool
		var palerain_option_reboot_device:			Bool
		var palerain_option_enter_recovery:			Bool
		var palerain_option_device_info:			Bool
		var palerain_option_no_colors:				Bool
		var palerain_option_bind_mount:				Bool
		var palerain_option_overlay:				Bool
		var palerain_option_force_revert:			Bool
		var palerain_option_safemode:				Bool
		var palerain_option_verbose_boot:			Bool
//		var palerain_option_sf_ssh:					Bool
//		var palerain_option_sf_launchdaemons:		Bool
//		var palerain_option_emerg_mode:				Bool
//		var palerain_option_jbinit_log_to_file:		Bool
		var palerain_option_cli:					Bool
		var palerain_option_telnetd:				Bool
		var palerain_option_quick:					Bool
		var palerain_option_jbinit_log_to_file:		Bool
		var palerain_option_setup_rootful_forced:	Bool
		var palerain_option_failure:				Bool
		var palerain_option_flower_chain:			Bool
		var palerain_option_test1:					Bool
		var palerain_option_test2:					Bool
		
		/// See flags in string format
		var flags: String {
			String(format: "0x%llx", LREnvironment.jbd.getFlags())
		}
		
		/// See flags in a string-list format
		var flagsList: String {
			let enabledFlags = Mirror(reflecting: self).children.compactMap {
				($0.value as? Bool) == true ? $0.label : nil
			}
			
			return "Flags: \(flags)\n\n" + enabledFlags.joined(separator: "\n")
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
			self.palerain_option_rootful				= (flags & (1 << 0))  != 0
			self.palerain_option_rootless				= (flags & (1 << 1))  != 0
			self.palerain_option_setup_rootful			= (flags & (1 << 2))  != 0
			// reserved
			self.palerain_option_setup_partial_root		= (flags & (1 << 4))  != 0
			self.palerain_option_checkrain_is_clone		= (flags & (1 << 5))  != 0
			self.palerain_option_rootless_livefs		= (flags & (1 << 6))  != 0
			self.palerain_option_ssv					= (flags & (1 << 7))  != 0
//			self.palerain_option_force_fakefs			= (flags & (1 << 8))  != 0
			self.palerain_option_clean_fakefs			= (flags & (1 << 9))  != 0
			self.palerain_option_tui					= (flags & (1 << 10)) != 0
			self.palerain_option_gui					= (flags & (1 << 11)) != 0
			self.palerain_option_dfuhelper_only 		= (flags & (1 << 12)) != 0
			self.palerain_option_pongo_exit				= (flags & (1 << 13)) != 0
			self.palerain_option_demote					= (flags & (1 << 14)) != 0
			self.palerain_option_pongo_full				= (flags & (1 << 15)) != 0
			self.palerain_option_palerain_version		= (flags & (1 << 16)) != 0
			self.palerain_option_exit_recovery			= (flags & (1 << 17)) != 0
			self.palerain_option_reboot_device			= (flags & (1 << 18)) != 0
			self.palerain_option_enter_recovery			= (flags & (1 << 19)) != 0
			self.palerain_option_device_info			= (flags & (1 << 20)) != 0
			self.palerain_option_no_colors				= (flags & (1 << 21)) != 0
			self.palerain_option_bind_mount				= (flags & (1 << 22)) != 0
			self.palerain_option_overlay				= (flags & (1 << 23)) != 0
			self.palerain_option_force_revert			= (flags & (1 << 24)) != 0
			self.palerain_option_safemode				= (flags & (1 << 25)) != 0
			self.palerain_option_verbose_boot			= (flags & (1 << 26)) != 0
//			self.palerain_option_sf_ssh					= (flags & (1 << 27)) != 0
//			self.palerain_option_sf_launchdaemons		= (flags & (1 << 28)) != 0
//			self.palerain_option_emerg_mode				= (flags & (1 << 29)) != 0
//			self.palerain_option_jbinit_log_to_file		= (flags & (1 << 30)) != 0
			self.palerain_option_cli					= (flags & (1 << 31)) != 0
			self.palerain_option_telnetd				= (flags & (1 << 32)) != 0
			self.palerain_option_quick					= (flags & (1 << 33)) != 0
			self.palerain_option_jbinit_log_to_file		= (flags & (1 << 50)) != 0
			self.palerain_option_setup_rootful_forced	= (flags & (1 << 51)) != 0
			self.palerain_option_failure				= (flags & (1 << 60)) != 0
			self.palerain_option_flower_chain			= (flags & (1 << 61)) != 0
			self.palerain_option_test1					= (flags & (1 << 62)) != 0
			self.palerain_option_test2					= (flags & (1 << 63)) != 0
		}
	}
	
	var palera1n: Flags {
		Flags()
	}
}
