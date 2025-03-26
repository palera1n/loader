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
						title: "UICache",
						action: {
							LREnvironment.execute(.binpack("/usr/bin/uicache"), ["-a"])
						}
					),
					SectionItem(
						title: "Restart Springboard", // we dont need to change this, its useless
						action: {
							self.blackOutController {
								LREnvironment.execute(.binpack("/bin/launchctl"), ["kickstart", "-k", "system/com.apple.backboardd"])
							}
						}
					),
					SectionItem(
						title: "Restart Userspace",
						action: {
							self.blackOutController {
								LREnvironment.execute(.binpack("/bin/launchctl"), ["reboot", "userspace"])
							}
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
						title: .localized("Device Info"),
						navigationDestination: LRSettingsAboutViewController()
					),
					SectionItem(
						title: .localized("Credits"),
						navigationDestination: LRSettingsCreditsViewController()
					)
				]
			)
		]
		
		addUserDefaultsStringSection(
			key: "defaultInstallPath",
			defaultValue: LREnvironment.default_config_url(),
			sectionTitle: "Download",
			changeTitle: "Change Download URL",
			keyboardType: .URL
		)
		
		if LREnvironment.shared.isBootstrapped == .bootstrapped {
			sections.append((
				title: .localized("Reset"),
				items: [
					SectionItem(
						title: .localized("Change Sudo Password"),
						action: {
							UIAlertController.showAlertForPasswordWithAuthentication(
								self,
								.localized("Authentication is required to change your sudo password."),
								alertTitle: .localized("Set Password"),
								alertMessage: .localized("Password Explanation")
							) { password in
								LREnvironment.shared.resetSudoPassword(with: password)
							}
						}
					),
					SectionItem(
						title: UIDevice.current.palera1n.canRevertSnapshot
						? String.localized("Clean FakeFS")
						: String.localized("Restore System"),
						tint: .systemRed,
						action: {
							
							let action = UIAlertAction(
								title: UIDevice.current.palera1n.canRevertSnapshot
								? String.localized("Clean FakeFS")
								: String.localized("Restore System"),
								style: .destructive
							) { _ in
								self.blackOutController {
									LREnvironment.shared.removeBootstrap()
								}
							}
							
							UIAlertController.showAlertWithCancel(
								self,
								title: UIDevice.current.palera1n.canRevertSnapshot
								? String.localized("Clean FakeFS Explanation", arguments: UIDevice.current.marketingModel)
								: String.localized("Restore System Explanation", arguments: UIDevice.current.marketingModel),
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
