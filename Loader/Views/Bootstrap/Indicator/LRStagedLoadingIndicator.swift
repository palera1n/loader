//
//  LoadingIndicator.swift
//  Loader
//
//  Created by samara on 16.03.2025.
//

import UIKit

class LRStagedLoadingIndicator: UIView {
    init() {
        super.init(frame: .zero)
		_setup()
    }
	
	private func _setup() {
		let image = UIImage(named: "Loading")
		
		let imageView = UIImageView(image: image)
		imageView.translatesAutoresizingMaskIntoConstraints = false
		
		self.addSubview(imageView)
		
		NSLayoutConstraint.activate([
			imageView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
			imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
			imageView.topAnchor.constraint(equalTo: self.topAnchor),
			imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor)
		])
		
		let animation: CABasicAnimation = CABasicAnimation.init(keyPath: "transform.rotation.z")
		animation.fromValue = 0.0
		animation.toValue = 2 * Double.pi
		animation.duration = 1.0
		animation.repeatCount = .infinity
		
		imageView.layer.add(animation, forKey: "rotationAnimation")
	}
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
