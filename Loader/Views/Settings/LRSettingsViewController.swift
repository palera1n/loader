//
//  SettingsViewController.swift
//  Loader
//
//  Created by samara on 9.03.2025.
//

import UIKit

// MARK: - Class
class LRSettingsViewController: LRBaseStructuredTableViewController {
	override func setupSections() {
		sections = [
			(
				title: "",
				items: [
					SectionItem(
						title: "Refresh Icon Cache",
						action: {
							LREnvironment.execute(.binpack("/usr/bin/uicache"), ["-a"])
						}
					),
					SectionItem(
						title: "Restart Springboard",
						action: {
							LREnvironment.execute(.binpack("/bin/launchctl"), ["kickstart", "-k", "system/com.apple.backboardd"])
						}
					),
					SectionItem(
						title: "Restart Userspace",
						action: {
							LREnvironment.execute(.binpack("/bin/launchctl"), ["reboot", "userspace"])
						}
					),
					SectionItem(
						title: "Reload Environment",
						action: {
							LREnvironment.jbd.reloadLaunchdJailbreakEnvironment()
						}
					)
				]
			),
			(
				title: "Other",
				items: [
					SectionItem(
						title: "Device Info",
						navigationDestination: LRSettingsAboutViewController()
					),
					SectionItem(
						title: "Credits",
						navigationDestination: LRSettingsCreditsViewController()
					)
				]
			)
		]
		
		if LREnvironment.shared.isBootstrapped == .bootstrapped {
			sections.append((
				title: "Reset",
				items: [
					SectionItem(
						title: "Change Sudo Password",
						action: {
							UIAlertController.showAlertForPasswordWithAuthentication(
								self,
								"Authentication is required to change your sudo password.",
								alertTitle: "Set Password",
								alertMessage: "In order to use command line tools like \"sudo\" after jailbreaking, you will need to set a terminal passcode. (This cannot be empty)"
							) { password in
								LREnvironment.shared.resetSudoPassword(with: password)
							}
						}
					),
					SectionItem(
						title: "Restore System",
						action: {
							
							let action = UIAlertAction(title: "Restore System", style: .destructive) { _ in
								LREnvironment.shared.removeBootstrap()
							}
							
							UIAlertController.showAlertWithCancel(
								self,
								title: "Uninstall jailbreak files and other changes made to the operating system, without erasing your data. This will reboot your \(UIDevice.current.marketingModel)",
								message: nil,
								style: .actionSheet,
								actions: [action]
							)
						}
					)
				]
			))
		}
	}
}
