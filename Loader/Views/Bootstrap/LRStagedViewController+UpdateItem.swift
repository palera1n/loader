//
//  LRStagedViewController+UpdateItem.swift
//  Loader
//
//  Created by samara on 18.03.2025.
//

import Foundation
import UIKit

// MARK: - Class extension: bootstrapperdelegate
extension LRStagedViewController: LRBootstrapperDelegate {
	func updateStepGroupFocus(for section: Int) {
		selectCollectionViewCell(for: section)
	}
	
	func bootstrapFinish() {
		Thread.mainBlock {
			UIApplication.shared.suspend()
		}
	}
}
