//
//  UIAlertController+Alerts.swift
//  Loader
//
//  Created by samara on 15.03.2025.
//

import UIKit.UIAlertController
#if os(iOS)
import LocalAuthentication
#endif
import NimbleExtensions

extension UIAlertController {
	/// Presents an alert
	/// - Parameters:
	///   - presenter: View where its presenting
	///   - title: Alert title
	///   - message: Alert message
	///   - actions: Alert actions
	static func showAlertWithCancel(
		_ presenter: UIViewController,
		title: String?,
		message: String?,
		style: UIAlertController.Style = .alert,
		actions: [UIAlertAction]
	) {
		var actions = actions
		actions.append(
			UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
		)
		
		showAlert(
			presenter,
			title: title,
			message: message,
			style: style,
			actions: actions
		)
	}
	/// Presents an alert
	/// - Parameters:
	///   - presenter: View where its presenting
	///   - title: Alert title
	///   - message: Alert message
	///   - actions: Alert actions
	static func showAlert(
		_ presenter: UIViewController,
		title: String?,
		message: String?,
		style: UIAlertController.Style = .alert,
		actions: [UIAlertAction]
	) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: style)
		actions.forEach { alert.addAction($0) }
		presenter.present(alert, animated: true)
	}
	/// Presents an alert to change sudo password
	/// - Parameters:
	///   - presenter: View where its presenting
	///   - title: Title for sudo password alert
	///   - message: Description for sudo password alert
	///   - completion: Completes with a password
	static func showAlertForPassword(
		_ presenter: UIViewController,
		title: String,
		message: String,
		completion: @escaping (String) -> Void
	) {
		let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
		
		alert.addTextField() { (password) in
			password.placeholder = "Password"
			password.isSecureTextEntry = true
			password.keyboardType = UIKeyboardType.asciiCapable
		}
		
		alert.addTextField() { (password) in
			password.placeholder = "Repeat Password"
			password.isSecureTextEntry = true
			password.keyboardType = UIKeyboardType.asciiCapable
		}
		
		let confirm = UIAlertAction(title: "Confirm", style: .default) { _ in
			let password = alert.textFields?[0].text
			completion(password!)
		}; confirm.isEnabled = false
		alert.addAction(confirm)
		
		NotificationCenter.default.addObserver(
			forName: UITextField.textDidChangeNotification,
			object: nil,
			queue: .main
		) { _ in
			let pass = alert.textFields?[0].text
			let passRepeated = alert.textFields?[1].text
			
			if !(pass!.count > 253 || passRepeated!.count > 253) {
				confirm.setValue("Confirm", forKeyPath: "title")
				confirm.isEnabled = !pass!.isEmpty && !passRepeated!.isEmpty && pass == passRepeated
			}
		}
		Thread.mainBlock {
			presenter.present(alert, animated: true)
		}
	}
	/// Presents an alert to change sudo password with authentication
	/// - Parameters:
	///   - presenter: View where its presenting
	///   - authMessage: The authentication method on why it needs it
	///   - alertTitle: Title for sudo password alert
	///   - alertMessage: Description for sudo password alert
	///   - completion: Completes with a password
	static func showAlertForPasswordWithAuthentication(
		_ presenter: UIViewController,
		_ authMessage: String,
		alertTitle: String,
		alertMessage: String,
		completion: @escaping (String) -> Void
	) {
		#if os(iOS)
		let context = LAContext()
		var error: NSError?
		#endif
		
		func change() {
			UIAlertController.showAlertForPassword(
				presenter,
				title: alertTitle,
				message: alertMessage
			) { password in
				completion(password)
			}
		}
		#if os(iOS)
		// if anyones changing the password ITS ME AND NO ONE ELSE (sorry nick)
		if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
			context.evaluatePolicy(
				.deviceOwnerAuthentication,
				localizedReason: authMessage
			) { success, _ in
				if success {
					change()
				}
			}
		} else {
			// If you have absolutely nothing (NO SECURITY, NO PASSCODE, NOTHING)
			// fuck it I'll let you change it anyway
			change()
		}
		#else
		change()
		#endif
	}
}
