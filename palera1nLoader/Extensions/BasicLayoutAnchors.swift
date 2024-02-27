//
//  BasicLayoutAnchors.swift
//  loader-rewrite
//
//  Created by samara on 1/29/24.
//

import Foundation
import UIKit

#warning("This is taken from https://github.com/NSAntoine/Antoine, thank you.")

/// A protocol describing a type which containing basic layout anchors
protocol BasicLayoutAnchorsHolding {
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
}

extension BasicLayoutAnchorsHolding {
    /// Activates constraints to completely cover this view/guide over another.
    func constraintCompletely<Target: BasicLayoutAnchorsHolding>(to target: Target) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: target.leadingAnchor),
            trailingAnchor.constraint(equalTo: target.trailingAnchor),
            bottomAnchor.constraint(equalTo: target.bottomAnchor),
            topAnchor.constraint(equalTo: target.topAnchor)
        ])
    }
    
    
}

extension UIView: BasicLayoutAnchorsHolding {}
extension UILayoutGuide: BasicLayoutAnchorsHolding {}
