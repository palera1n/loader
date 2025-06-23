//
//  SettingsViewController.swift
//  Loader
//
//  Created by samara on 9.03.2025.
//

import UIKit
import NimbleViewControllers

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
				title: .localized("Other"),
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
			sectionTitle: .localized("Download"),
			changeTitle: .localized("Change Download URL"),
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
						title: UIDevice.current.palera1n.shouldCleanFakefs
						? .localized("Clean FakeFS")
						: .localized("Restore System"),
						tint: .systemRed,
						action: {
							let action = UIAlertAction(
								title: UIDevice.current.palera1n.shouldCleanFakefs
								? .localized("Clean FakeFS")
								: .localized("Restore System"),
								style: .destructive
							) { _ in
								self.blackOutController {
									LREnvironment.shared.removeBootstrap()
								}
							}
							
							let style: UIAlertController.Style = UIDevice.current.userInterfaceIdiom == .pad
							? .alert
							: .actionSheet
							
							UIAlertController.showAlertWithCancel(
								self,
								title: UIDevice.current.palera1n.shouldCleanFakefs
								? .localized("Clean FakeFS Explanation", arguments: UIDevice.current.marketingModel)
								: .localized("Restore System Explanation", arguments: UIDevice.current.marketingModel),
								message: nil,
								style: style,
								actions: [action]
							)
						}
					)
				]
			))
		}
		
	}
}
extension LRBaseStructuredTableViewController {
	@discardableResult
	func addUserDefaultsStringSection(
		key: String,
		defaultValue: String,
		sectionTitle: String,
		changeTitle: String = "",
		sectionIndex: Int? = nil,
		keyboardType: UIKeyboardType = .default
	) -> String {
		let userDefaults = UserDefaults.standard
		let currentValue = userDefaults.string(forKey: key) ?? defaultValue
		let isModified = currentValue != defaultValue
		
		var sectionItems: [SectionItem] = []
		
		if isModified {
			sectionItems = [
				SectionItem(
					title: currentValue,
					tint: .secondaryLabel,
					action: { [weak self] in
						UIAlertController.showAlertForStringChange(
							self!,
							title: changeTitle,
							currentValue: currentValue,
							keyboardType: keyboardType,
							completion: { newValue in
								userDefaults.set(newValue, forKey: key)
								self?.setupSections()
								self?.tableView.reloadData()
							}
						)
					}
				),
				SectionItem(
					title: .localized("Reset Configuration"),
					tint: .systemRed,
					action: { [weak self] in
						userDefaults.removeObject(forKey: key)
						self?.setupSections()
						self?.tableView.reloadData()
					}
				)
			]
		} else {
			sectionItems = [
				SectionItem(
					title: changeTitle,
					tint: .tintColor,
					action: { [weak self] in
						UIAlertController.showAlertForStringChange(
							self!, title: changeTitle,
							currentValue: currentValue,
							keyboardType: keyboardType,
							completion: { newValue in
								userDefaults.set(newValue, forKey: key)
								self?.setupSections()
								self?.tableView.reloadData()
							}
						)
					}
				)
			]
		}
		
		let newSection = (title: sectionTitle, items: sectionItems)
		
		if 
			let index = sectionIndex,
			sections.count > index
		{
			sections.insert(newSection, at: index)
		} else {
			sections.append(newSection)
		}
		
		return currentValue
	}
}
