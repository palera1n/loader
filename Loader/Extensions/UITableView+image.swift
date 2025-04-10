//
//  UITableView+image.swift
//  Loader
//
//  Created by samara on 10.04.2025.
//

import UIKit.UITableViewCell

extension UITableViewCell {
	/// Applies a properly sized and styled image to the cell's imageView
	/// - Parameter originalImage: The original image to resize and apply
	func setSectionImage(with originalImage: UIImage) {
		let imageSize = CGSize(width: 30, height: 30)
		
		let resizedImage = UIGraphicsImageRenderer(size: imageSize).image { context in
			originalImage.draw(in: CGRect(origin: .zero, size: imageSize))
		}
		
		self.imageView?.image = resizedImage
		self.imageView?.layer.cornerRadius = 7
		self.imageView?.clipsToBounds = true
		self.imageView?.layer.borderWidth = 0.7
		self.imageView?.layer.cornerCurve = .continuous
		self.imageView?.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
	}
}
