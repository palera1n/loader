//
//  Bootstrap.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/12/23.
//

import Foundation
import UIKit

class bootstrap {

    // Ran after bootstrap/deb install
    static public func cleanUp() -> Void {
        
        let pathsToClear = ["/var/mobile/Library/palera1n/downloads", "/var/mobile/Library/palera1n/temp"]
        for path in pathsToClear {
            let files = try! FileManager.default.contentsOfDirectory(atPath: path)
            for file in files {
                binpack.rm("\(path)/\(file)")
            }
        }
        
        let palera1nDir = try! FileManager.default.contentsOfDirectory(atPath: "/var/mobile/Library/palera1n")
        for file in palera1nDir {
            if (file.contains("revision") || file.contains("loader.log")) {
                binpack.rm("/var/mobile/Library/palera1n/\(file)")
            }
        }

        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
        
        do {
            let tmp = URL(string: NSTemporaryDirectory())!
            let tmpFile = try FileManager.default.contentsOfDirectory(at: tmp, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for url in tmpFile {try FileManager.default.removeItem(at: url)}}
        catch {
            return
        }
    }
    

    static public func installDebian(deb: String, completion: @escaping (String?, Int?) -> Void) {
        var ret = helper(args: ["-d", deb])
        if (ret != 0) {
            completion(local("DPKG_ERROR"), ret)
            return
        }

        ret = spawn(command: "/cores/binpack/usr/bin/uicache", args: ["-a"], root: true)
        if (ret != 0) {
            completion(local("ERROR_UICACHE"), ret)
            return
        }
        
        cleanUp()
        completion(local("DONE_INSTALL"), 0)
        return
    }
    
    
    static public func installBootstrap(tar: String, deb: String, completion: @escaping (String?, Int?) -> Void) {
        let debPath = "/var/mobile/Library/palera1n/downloads/\(deb)"
        var ret = helper(args: ["--install", tar, debPath])
        if (ret != 0) {
            completion(local("ERROR_STRAP"), ret)
            return
        }
        
        ret = spawn(command: "/cores/binpack/usr/bin/uicache", args: ["-a"], root: true)
        if (ret != 0) {
            completion(local("ERROR_UICACHE"), ret)
            return
        }

        cleanUp()
        completion(local("DONE_INSTALL"), 0)
        return
    }
    
    
    static public func revert(viewController: UIViewController) -> Void {
        if !envInfo.isRootful {
            let alert = UIAlertController.spinnerAlert("REMOVING")
            viewController.present(alert, animated: true)
            helper(args: ["-R"])
            
            if (envInfo.rebootAfter) {
                helper(args: ["-r"])
            } else {
                let errorAlert = UIAlertController.error(title: local("DONE_REVERT"), message: local("CLOSE_APP"))
                alert.dismiss(animated: true) {
                    viewController.present(errorAlert, animated: true)
                }
            }
        }
    }
}

