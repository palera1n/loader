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

extension UIListContentConfiguration {
	/// Returns a modified configuration with a styled and resized section image.
	/// - Parameters:
	///   - originalImage: The image to resize and apply.
	///   - imageSize: The size to resize the image to. Defaults to 30×30.
	func applyingSectionImage(_ originalImage: UIImage, imageSize: CGSize = CGSize(width: 30, height: 30)) -> UIListContentConfiguration {
		let resizedImage = UIGraphicsImageRenderer(size: imageSize).image { _ in
			originalImage.draw(in: CGRect(origin: .zero, size: imageSize))
		}.withRenderingMode(.alwaysOriginal)
		
		var config = self
		config.image = resizedImage
		config.imageToTextPadding = 12
		config.imageProperties.cornerRadius = 7
		config.imageProperties.reservedLayoutSize = imageSize
		config.imageProperties.maximumSize = imageSize
		config.imageProperties.tintColor = nil
		
		return config
	}
}
