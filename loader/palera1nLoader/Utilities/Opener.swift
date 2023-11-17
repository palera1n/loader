//
//  AppOpener.swift
//  palera1nLoader
//
//  Created by Staturnz on 6/11/23.
//

import Foundation
import Extras

class opener {
    
    @discardableResult
    static public func openApp(_ bundle: String) -> Bool {
        return LSApplicationWorkspace.default().openApplication(withBundleID: bundle)
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
