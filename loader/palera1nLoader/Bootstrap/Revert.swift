//
//  Revert.swift
//  palera1nLoader
//
//  Created by Staturnz on 5/1/23.
//

import Foundation
import UIKit

class Revert {
    
    @discardableResult func bp_rm(_ file: String) -> Int {
        return spawn(command: "/cores/binpack/bin/rm", args: ["-rf", file], root: true)
    }
    
    @discardableResult func bp_uicache(_ arg: String,_ file: String? = nil) -> Int {
        if (file != nil) {
            return spawn(command: "/cores/binpack/usr/bin/uicache", args: [arg, file!], root: true)
        }
        return spawn(command: "/cores/binpack/usr/bin/uicache", args: [arg], root: true)
    }
    
    func removeLeftovers() -> Void {
        let remove = ["/var/lib","/var/cache","/var/LIB","/var/Liy","/var/LIY",
                      "/var/sbin","/var/bin","/var/ubi","/var/ulb","/var/local",
                      "/var/mobile/Library/Application Support/xyz.willy.Zebra",
                      "/var/mobile/Library/Cydia","/var/mobile/Library/Sileo",
                      "/var/dropbear_rsa_host_key","/var/tmp/palera1nloader/downloads",
                      "/var/tmp/palera1nloader/temp","/var/tmp/xyz.willy.Zebra"]
        
        for path in remove {
            if (fileExists(path)) {
                log(type: .info, msg: "Removing directory: /var/mobile/Library/Preferences/\(path)")
                self.bp_rm(path)
            }
        }
    }
    
    func revert(viewController: UIViewController) -> Void {
        if !envInfo.isRootful {
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
            let alert = UIAlertController.spinnerAlert("REMOVING")
            viewController.present(alert, animated: true)
            
            let apps = try? FileManager.default.contentsOfDirectory(atPath: "/var/jb/Applications")
            for app in apps ?? [] {
                if app.hasSuffix(".app") {
                    let ret = bp_uicache("-u", "/var/jb/Applications/\(app)")
                    let domain = String((Bundle(path: "/var/jb/Applications/\(app)")?.bundleIdentifier)!)
                    log(type: .info, msg: domain)
                    UserDefaults.standard.removePersistentDomain(forName: domain)
                    UserDefaults.standard.synchronize()
                    if ret != 0 {
                        let errorAlert = UIAlertController.error(title: "Failed to unregister \(app)", message: "Status: \(ret)");
                        alert.dismiss(animated: true) {
                            viewController.present(errorAlert, animated: true)
                        }
                        return
                    }
                }
            }
            
            bp_rm("/var/jb")
            
            if (envInfo.jbFolder != "") {
                bp_rm(envInfo.jbFolder)
            } else {
                bp_rm("/private/preboot/\(envInfo.bmHash)/procursus")
            }
            
            removeLeftovers()
            bp_uicache("-a")
            
            if (envInfo.rebootAfter) {
                //helperCmd(["-d"])
            } else {
                let errorAlert = UIAlertController.error(title: local("DONE_REVERT"), message: local("CLOSE_APP"))
                alert.dismiss(animated: true) {
                    viewController.present(errorAlert, animated: true)
                }
            }
        }
    }
}
