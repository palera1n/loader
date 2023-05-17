//
//  AppDelegate.swift
//  Pogo
//
//  Created by Amy While on 12/09/2022.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Utils().createLoaderDirs()
        initLogs()
        let viewController = ViewController()
        let navController = UINavigationController(rootViewController: viewController)
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        window?.isOpaque = false
        window?.backgroundColor = .clear
        return true
    }
    
    public func applicationDidBecomeActive(_ application: UIApplication) {
        window?.isOpaque = false
        UIView.animate(withDuration: 0.4, animations: {
            self.window?.backgroundColor = .clear
        })
    }
    public func applicationWillResignActive(_ application: UIApplication) {
        window?.isOpaque = true
        UIView.animate(withDuration: 0.4, animations: {
            self.window?.backgroundColor = .systemBackground
        })
    }

}

