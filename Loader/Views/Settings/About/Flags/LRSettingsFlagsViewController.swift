//
//  LRSettingsFlagsViewController.swift
//  Loader
//
//  Created by samara on 13.03.2025.
//

import UIKit
import NimbleViewControllers

// MARK: - Class
class LRSettingsFlagsViewController: LRBaseStructuredTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
		title = "Flags"
    }
	
	override func setupSections() {
		sections = [
			(
				title: "",
				items: [
					SectionItem(
						title: UIDevice.current.palera1n.flagsList
					),
				]
			),
		]
	}
}
