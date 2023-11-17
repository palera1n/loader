//
//  AppOpener.swift
//  palera1nLoader
//
//  Created by Staturnz on 6/11/23.
//

import Foundation
import Extras

@objc private protocol LSApplicationWorkspace {
    static func defaultWorkspace() -> Self
    func openApplication(withBundleID arg1: String) -> Bool
}

class opener {
    @discardableResult
    public static func openApp(_ bundle: String) -> Bool {
        guard let LSApplicationWorkspace = NSClassFromString("LSApplicationWorkspace") else {
            log(type: .error, msg: "failed to find the LSApplicationWorkspace class")
            return false
        }

        guard let defaultWorkspace = (LSAppWorkspace as AnyObject).perform(
            NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue() else {
            log(type: .error, msg: "failed to find the defaultWorkspace")
            return false
        }

        let selector = NSSelectorFromString("openApplicationWithBundleID:")
        let method = class_getMethodImplementation(LSApplicationWorkspace, selector)

        typealias f = @convention(c) (AnyObject, Selector, NSString) -> Bool
        return unsafeBitCast(method, to: f.self)(defaultWorkspace, selector, bundle as NSString)
    }
    
    static public func TrollHelper() -> Void {
        if !openApp("com.opa334.trollstorepersistencehelper") {
            let fm = FileManager.default
            let contents = try! fm.contentsOfDirectory(atPath: "/var/containers/Bundle/Application")
            for uuid in contents {
                do {
                    let contentsuuid = try fm.contentsOfDirectory(atPath: "/var/containers/Bundle/Application/\(uuid)")
                    let appFolder = contentsuuid.filter { $0.hasSuffix("app") }
                    for app in appFolder {
                        if (fileExists("/var/containers/Bundle/Application/\(uuid)/\(app)/trollstorehelper") && app != "TrollStore.app") {
                            openApp(Bundle(path: "/var/containers/Bundle/Application/\(uuid)/\(app)")!.bundleIdentifier!)
                        }
                    }
                } catch {
                    log(type: .fatal, msg: "Failed to get contents of directory: \(error.localizedDescription)")
                }
            }
        }
    }
}
