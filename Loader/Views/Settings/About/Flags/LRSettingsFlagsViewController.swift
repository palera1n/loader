//
//  LRSettingsFlagsViewController.swift
//  Loader
//
//  Created by samara on 13.03.2025.
//

import UIKit

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
						title: "",
						subtitle: UIDevice.current.palera1n.flagsList,
						style: .subtitle
					),
				]
			),
		]
	}
}
