//
//  AppDelegate.swift
//  Loader
//
//  Created by samara on 9.03.2025.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		UIApplication.shared.isIdleTimerDisabled = true
		self._createTmpDir()
		return true
	}

	// MARK: UISceneSession Lifecycle

	func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
		UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}
	
	func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		handle(url: url)
	}
	
	func handle(url: URL) -> Bool {
		if let host = url.host {
			if host == "restart-pineboard" || host == "restart-springboard" {
				LREnvironment.shared.respring()
			}
			
			if host == "userspace-reboot" {
				LREnvironment.shared.rebootUserspace()
			}
			
			if host == "uicache" {
				LREnvironment.shared.uicacheAll()
			}
			
			if let config = url.absoluteString.range(of: "/config/") {
				let fullPath = String(url.absoluteString[config.upperBound...])
				
				if let configURL = URL(string: fullPath),
				   let scheme = configURL.scheme?.lowercased(),
				   (scheme == "http" || scheme == "https"),
				   configURL.pathExtension.lowercased() == "json" {
					UserDefaults.standard.set(fullPath, forKey: "defaultInstallPath")
				} else {
					print("The URL must be a valid json URL!")
				}
			}
		}

		return true
	}

	func applicationWillTerminate(_ application: UIApplication) {
		self._cleanTmpDir()
	}
	
	private func _createTmpDir() {
		do {
			try FileManager.default.createDirectory(
				atPath: .tmp(),
				withIntermediateDirectories: true,
				attributes: nil
			)
		} catch {
			print("Failed to create directory: \(error.localizedDescription)")
		}
	}
	
	private func _cleanTmpDir() -> Void {
		let fileManager = FileManager.default
				
		do {
			if fileManager.fileExists(atPath: .tmp()) {
				try fileManager.removeItem(atPath: .tmp())
			}
		} catch {
			print("Failed to remove directory: \(error.localizedDescription)")
		}
	}
}
