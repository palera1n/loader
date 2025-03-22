//
//  UICollectionViewDiffableDataSource+refresh.swift
//
//
//  Created by samara on 22.03.2025.
//

import UIKit

extension UICollectionViewDiffableDataSource {
	public func refresh(completion: (() -> Void)? = nil) {
		self.apply(self.snapshot(), animatingDifferences: true, completion: completion)
	}
}
