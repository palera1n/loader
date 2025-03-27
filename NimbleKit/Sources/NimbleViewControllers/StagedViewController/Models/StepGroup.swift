//
//  Step.swift
//  Loader
//
//  Created by samara on 18.03.2025.
//

import Foundation
import UIKit

public struct StepGroup: Hashable, Identifiable {
	public let id: UUID
	public let name: String
	public var items: [StepGroupItem]
	
	public init(id: UUID = UUID(), name: String, items: [StepGroupItem]) {
		self.id = id
		self.name = name
		self.items = items
	}
	
	public func item(named name: String) -> StepGroupItem? {
		return items.first { $0.name == name }
	}
}

public struct StepGroupItem: Hashable, Identifiable {
	public let id: UUID
	public let name: String
	public var status: StepStatus
	
	public init(id: UUID = UUID(), name: String, status: StepStatus = .pending) {
		self.id = id
		self.name = name
		self.status = status
	}
}

public enum StepStatus: String, CaseIterable {
	case pending
	case inProgress
	case completed
	case failed
	
	var systemImageName: String {
		switch self {
		case .pending:     return "circle.dotted"
		case .inProgress:  return "circle.dashed"
		case .completed:   return "checkmark.circle.fill"
		case .failed:      return "xmark.circle.fill"
		}
	}
	
	var tintColor: UIColor {
		switch self {
		case .pending:     return .systemGray.withAlphaComponent(0.4)
		case .inProgress:  return .systemBlue
		case .completed:   return .systemGreen
		case .failed:      return .systemRed
		}
	}
}
