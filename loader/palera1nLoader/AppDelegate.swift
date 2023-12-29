//
//  AppDelegate.swift
//  palera1nLoader
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var launchedShortcutItem: UIApplicationShortcutItem?
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        Check.loaderDirectories()
        initLogs()
        Check.prerequisites()

        
        let viewController = JsonVC()
        let diagnosticsController = DiagnosticsVC()

        if UIDevice.current.userInterfaceIdiom == .pad {
            let masterNavController = UINavigationController(rootViewController: viewController)
            let detailNavController = UINavigationController(rootViewController: diagnosticsController)
            
            let splitViewController = UISplitViewController()
            splitViewController.viewControllers = [masterNavController, detailNavController]
            splitViewController.preferredDisplayMode = UISplitViewController.DisplayMode.oneBesideSecondary
            
            window = UIWindow(frame: UIScreen.main.bounds)
            window?.rootViewController = splitViewController
            window?.makeKeyAndVisible()
        } else {
            let navController = UINavigationController(rootViewController: viewController)
            window = UIWindow(frame: UIScreen.main.bounds)
            window?.rootViewController = navController
            window?.makeKeyAndVisible()
        }
        return true
    }
}
