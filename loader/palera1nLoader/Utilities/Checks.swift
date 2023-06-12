//
//  Checks.swift
//  palera1nLoader
//
//  Created by Staturnz on 6/11/23.
//

import Foundation
import UIKit
import Extras
import MachO

struct environment {
    var env_type: Int!
    var jb_folder: String?
}

class Check {
    
    static public func installation() -> environment {
        if (envInfo.isSimulator) {
            return environment(env_type: -1, jb_folder: nil)
        }
        
        if (envInfo.isRootful) {
            return environment(env_type: 0, jb_folder: nil)
        }
        
        let dir = "/private/preboot/\(envInfo.bmHash)"
        var value = Int()
        var jbFolders = [String()]
        
        do {
            let contents = try fm.contentsOfDirectory(atPath: dir)
            jbFolders = contents.filter { $0.hasPrefix("jb-") }
            let jbFolderExists = !jbFolders.isEmpty
            let jbSymlinkPath = "/var/jb"
            let jbSymlinkExists = fm.fileExists(atPath: jbSymlinkPath)
            
            if jbFolderExists && jbSymlinkExists {
                log(type: .info, msg: "Found jb- folders and /var/jb exists.")
                value = 1
            } else if jbFolderExists && !jbSymlinkExists {
                log(type: .info, msg: "Found jb- folders but /var/jb does not exist.")
                value = 2
            } else {
                log(type: .info, msg: "jb-XXXXXXXX does not exist")
                value = 0
            }
        } catch {
            log(type: .fatal, msg: "Failed to get contents of directory: \(error.localizedDescription)")
        }
        
        if value == 0 {
            return environment(env_type: 0, jb_folder: nil)
        } else {
            return environment(env_type: value, jb_folder: "\(dir)/\(jbFolders[0])")
        }
    }
    
    @discardableResult
    static public func loaderDirectories() -> Bool {
        if (!fileExists("/var/mobile/Library/palera1n")) {
            
            let dirs = ["/var/mobile/Library/",
                        "/var/mobile/Library/palera1n/temp",
                        "/var/mobile/Library/palera1n/downloads",
                        "/var/mobile/Library/palera1n/logs"]
            
            do {
                for path in dirs { try fm.createDirectory(atPath: path, withIntermediateDirectories: true) }
            } catch {
                log(type: .error, msg: "Failed to create temp directories: \(error)")
                return false
            }
        }
     
        if let revision = Bundle.main.infoDictionary?["REVISION"] as? String {
            FileManager.default.createFile(atPath: "/var/mobile/Library/palera1n/.revision-\(revision)", contents: nil)
        } else {
            log(type: .error, msg: "Failed to find revision string")
            return false
        }
        
        return true
    }
    
    @discardableResult
    static public func helperSymlink() -> Bool {
        let path = "/var/mobile/Library/palera1n/helper"
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
        #if targetEnvironment(simulator)
            envInfo.isSimulator = true
        #endif
        
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

        // is installed check
        if fileExists("/.procursus_strapped") || fileExists("/var/jb/.procursus_strapped") {
            envInfo.isInstalled = true
        }
        
        // device info
        envInfo.systemVersion = "\(local("VERSION_INFO")) \(UIDevice.current.systemVersion)"
        envInfo.systemArch = String(cString: NXGetLocalArchInfo().pointee.name)
        
        // jb-XXXXXXXX and /var/jb checks
        envInfo.envType = Check.installation().env_type
        //envInfo.jbFolder = strapCheck().jbFolders[0]
        
        // sileo installed check
        if (fileExists("/Applications/Sileo.app") || fileExists("/var/jb/Applications/Sileo.app") ||
            fileExists("/Applications/Sileo-Nightly.app") || fileExists("/var/jb/Applications/Sileo-Nightly.app")) {
            envInfo.sileoInstalled = true
        }
        
        // zebra installed check
        if (fileExists("/Applications/Zebra.app") || fileExists("/var/jb/Applications/Zebra.app")) {
            envInfo.zebraInstalled = true
        }
        
        envInfo.hasChecked = true
        log(msg: "## palera1nLoader logs ##")
        log(msg: "Jailbreak Type: \(envInfo.isRootful ? "Rootful" : "Rootless")")
        log(msg: "Environment: \(envInfo.envType)")
        log(msg: "iOS: \(envInfo.systemVersion)")
        log(msg: "Arch: \(envInfo.systemArch)")
        log(msg: "Installed: \(envInfo.isInstalled)")
        log(msg: "Force Reverted: \(envInfo.hasForceReverted)")
        log(msg: "Sileo Installed: \(envInfo.sileoInstalled)")
        log(msg: "Zebra Installed: \(envInfo.zebraInstalled)")
        log(msg: "kinfo: \(envInfo.kinfoFlags)")
        log(msg: "pinfo: \(envInfo.pinfoFlags)")
        log(msg: "CoreFoundation: \(envInfo.CF)")
        log(msg: "Hash: \(envInfo.bmHash)")
    }
}
