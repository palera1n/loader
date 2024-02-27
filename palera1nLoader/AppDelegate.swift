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
        initLogs()
        
        let viewController = ViewController()
        let navController = UINavigationController(rootViewController: viewController)
        window = UIWindow(frame: UIScreen.main.bounds)
        if #available(iOS 13.0, *) {
            window?.backgroundColor = .systemGroupedBackground
        } else {
            window?.backgroundColor = .systemGray
        }
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        return true
    }

}

