//
//  UIScreen+displayCornerRadius.swift
//  Loader
//
//  Created by samara on 9.03.2025.
//

import UIKit.UIScreen

extension UIScreen {
	/// Physical screen corner radius
	public var screenCornerRadius: CGFloat {
		guard
			let data = Data(base64Encoded: "X2Rpc3BsYXlDb3JuZXJSYWRpdXM="),
			let propertyString = String(data: data, encoding: .utf8)
		else {
			return 0
		}
		
		return UIScreen.main.value(forKey: propertyString) as? CGFloat ?? 0
	}
}
