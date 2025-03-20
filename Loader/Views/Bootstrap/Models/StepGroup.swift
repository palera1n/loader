//
//  Step.swift
//  Loader
//
//  Created by samara on 18.03.2025.
//

import Foundation
import UIKit

struct StepGroup: Hashable, Identifiable {
    let id = UUID()
    let name: String
    var items: [StepGroupItem]
    
    func item(named name: String) -> StepGroupItem? {
        return items.first { $0.name == name }
    }
}

struct StepGroupItem: Hashable, Identifiable {
    let id = UUID()
    let name: String
    var status: StepStatus = .pending
}

enum StepStatus: String, CaseIterable {
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
