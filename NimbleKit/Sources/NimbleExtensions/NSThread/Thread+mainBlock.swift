//
//  Thread.swift
//  Loader
//
//  Created by samara on 15.03.2025.
//

import Foundation.NSThread

extension Thread {
	/// Block to always execute code on the main thread
	/// - Parameter block: Code
	public class func mainBlock(_ block: @escaping () -> Void) {
		if Thread.isMainThread {
			block()
		} else {
			DispatchQueue.main.async {
				block()
			}
		}
	}
}
