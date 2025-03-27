//
//  LRBootstrapper+status.swift
//  Loader
//
//  Created by samara on 18.03.2025.
//

import NimbleViewControllers

// MARK: - Class extension: status
extension LRBootstrapper {
	public func setItemStatus(_ section: String, item: String, with status: StepStatus) {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
			self.callback?.updateStepItemStatus(section, item: item, with: status)
		}
	}
	
	
	public func setLastItemStatusAndNew(_ section: String, item: String) {
		if let last = lastStatusItem {
			setItemStatus(last.section, item: last.item, with: .completed)
		}
		
		self.lastStatusItem = (section, item)
		self.setItemStatus(section, item: item, with: .inProgress)
	}
	
	public func setGroupFocus(for section: Int) {
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
			self.callback?.updateStepGroupFocus(for: section)
		}
	}
}
