//
//  Checks.swift
//  palera1nLoader
//
//  Created by Staturnz on 6/11/23.
//

import Foundation
import UIKit
import MachO

struct environment {
    var env_type: Int!
    var jb_folder: String?
}

enum installStatus {
    case simulated
    case rootful
    case rootful_installed
    case rootless
    case rootless_installed
}

class Check {
    
    static public func installation() -> installStatus {
        #if targetEnvironment(simulator)
        return .simulated
        #else
        if envInfo.isRootful {
            if fm.fileExists(atPath: "/.procursus_strapped") {
                return .rootful_installed
            } else {
                return .rootful
            }
        }
        
        let dir = "/private/preboot/\(envInfo.bmHash)"
        var jbFolders = [String]()
        
        do {
            let contents = try fm.contentsOfDirectory(atPath: dir)
            jbFolders = contents.filter { $0.hasPrefix("jb-") }
            let jbFolderExists = !jbFolders.isEmpty
            let jbSymlinkPath = "/var/jb"
            let jbSymlinkExists = fm.fileExists(atPath: jbSymlinkPath)
            
            if jbFolderExists && jbSymlinkExists {
                return .rootless_installed
            } else {
                return .rootless
            }
        } catch {
            log(type: .fatal, msg: "Failed to get contents of directory: \(error.localizedDescription)")
            return .rootless
        }
        #endif
    }
    
    @discardableResult
    static public func loaderDirectories() -> Bool {
        if (!fileExists("/tmp/palera1n")) {
            
            let dirs = ["/tmp/palera1n/logs", "/tmp/palera1n/temp"]
            
            do {
                for path in dirs { try fm.createDirectory(atPath: path, withIntermediateDirectories: true) }
            } catch {
                log(type: .error, msg: "Failed to create temp directories: \(error)")
                return false
            }
        }
        
        return true
    }
    
    @discardableResult
    static public func helperSymlink() -> Bool {
        let path = "/tmp/palera1n/helper"
        if (fileExists("/cores/jbloader")) {
            if (fileExists(path)) {
                log(type: .info, msg: "helper symlink already exists.")
            } else {
                let ret = binpack.ln("/cores/jbloader", path)
                if (ret != 0) {
                    log(type: .fatal, msg: "Failed to create helper symlink.")
                    return false
                }
                chmod(path, 0755)
            }
        } else {
            log(type: .fatal, msg: "Failed to find jbloader")
            return false
        }
        
        return true
    }
    
    static public func prerequisites() -> Void {
        Check.helperSymlink()
        
        // rootless/rootful check
        helper(args: ["-t"])
        envInfo.installPrefix = envInfo.isRootful ? "" : "/var/jb"
        
        // force revert check
        helper(args: ["-f"])

        // get paleinfo and kerninfo flags
        helper(args: ["-k"])
        helper(args: ["-p"])
        helper(args: ["-S"])
        helper(args: ["-s"])
        
        // get bmhash
        helper(args: ["-b"])
        
        envInfo.hasChecked = true
        log(msg: "## Loader logs ##")
        log(msg: "Jailbreak Type: \(envInfo.isRootful ? "Rootful" : "Rootless")")
        log(msg: "iOS: \(UIDevice.current.systemVersion)")
        log(msg: "kinfo: \(envInfo.kinfoFlags)")
        log(msg: "pinfo: \(envInfo.pinfoFlags)")
        log(msg: "CoreFoundation: \(envInfo.CF)")
    }
}
