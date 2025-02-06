//
//  AppDelegate.swift
//  loader-rewrite
//
//  Created by samara on 1/29/24.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let viewController = ViewController()
        let navController = UINavigationController(rootViewController: viewController)
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
		if let host = url.host {

			if host == "restart-pineboard" || host == "restart-springboard" {
				spawn(command: "/cores/binpack/bin/launchctl", args: ["kickstart", "-k", "system/com.apple.backboardd"])
			}

			if host == "userspace-reboot" {
				spawn(command: "/cores/binpack/bin/launchctl", args: ["reboot", "userspace"])
			}

			if host == "uicache" {
				spawn(command: "/cores/binpack/usr/bin/uicache", args: ["-a"])
			}

			if let config = url.absoluteString.range(of: "/config/") {
				let fullPath = String(url.absoluteString[config.upperBound...])
				
				if OptionsViewController().isValidURL(fullPath) {
					Preferences.installPath = fullPath
				} else {
					log(type: .fatal, msg: "The URL must be a valid json URL!")
				}
			}
		}
        return true
    }
}

