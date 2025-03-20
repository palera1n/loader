//
//  LRSettingsAboutViewController.swift
//  Loader
//
//  Created by samara on 9.03.2025.
//

import UIKit

// MARK: - Class
class LRSettingsAboutViewController: LRBaseStructuredTableViewController {
	let device = UIDevice.current
	
	override func viewDidLoad() {
		super.viewDidLoad()
		title = "Device Info"
	}
	
	override func setupSections() {
		sections = [
			(
				title: "palera1n",
				items: [
//					SectionItem(
//						title: "Version",
//						subtitle: Bundle.appVersionShort
//					),
					SectionItem(
						title: "Type",
						subtitle: device.palera1n.palerain_option_rootless ? "rootless" : "rootful"
					),
					SectionItem(
						title: "Flags",
						subtitle: device.palera1n.flags,
						navigationDestination: LRSettingsFlagsViewController()
					),
					SectionItem(
						title: "Bootstrapped",
						subtitle: "\(String(describing: LREnvironment.shared.isBootstrapped))"
					)
				]
			),
			(
				title: device.marketingModel,
				items: [
					SectionItem(
						title: "Version",
						subtitle: device.systemVersion
					),
					SectionItem(
						title: "Model",
						subtitle: device.marketingModel
					),
					SectionItem(
						title: "Architecture",
						subtitle: device.architecture
					)
				]
			),
			(
				title: "System",
				items: [
					SectionItem(
						title: "CF",
						subtitle: device.cfVersion.standard
					),
					SectionItem(
						title: "Kernel",
						subtitle: device.kernelVersion
					)
				]
			),
			(
				title: "Other",
				items: [
					SectionItem(
						title: "boot-manifest-hash",
						subtitle: device.bootmanifestHash ?? "",
						style: .subtitle
					),
					SectionItem(
						title: "boot-args",
						subtitle: device.bootArgs,
						style: .subtitle
					)
				]
			)
		]
	}
}

