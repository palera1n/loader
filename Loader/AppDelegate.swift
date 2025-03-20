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
		// Called when a new scene session is being created.
		// Use this method to select a configuration to create the new scene with.
		return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
	}

	func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
		// Called when the user discards a scene session.
		// If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
		// Use this method to release any resources that were specific to the discarded scenes, as they will not return.
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

