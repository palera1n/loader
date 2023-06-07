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
        Utils().createLoaderDirs()
        initLogs()
        
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
        
        

        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            launchedShortcutItem = shortcutItem
            switch shortcutItem.type {
            case "qa_respring":
                spawn(command: "/cores/binpack/bin/launchctl", args: ["kickstart", "-k", "system/com.apple.backboardd"], root: true)
            case "qa_uicache":
                spawn(command: "/cores/binpack/usr/bin/uicache", args: ["-a"], root: true)
            default:
                print("Unknown Option")
            }
            return false
        }
    
        return true
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        switch shortcutItem.type {
        case "qa_respring":
            spawn(command: "/cores/binpack/bin/launchctl", args: ["kickstart", "-k", "system/com.apple.backboardd"], root: true)
        case "qa_uicache":
            spawn(command: "/cores/binpack/usr/bin/uicache", args: ["-a"], root: true)
        default:
            print("Unknown Option")
        }
    }
    
}
