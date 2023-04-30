//
//  Utilities.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/16/23.
//

import Foundation
import UIKit
import MachO

class Utils {
    func strapCheck() -> (env: Int, jbFolder: String) {
        if (envInfo.isSimulator) {
            return (-1, "")
        }
        if (envInfo.isRootful) {
            return (0, "")
        }
        
        let directoryPath = "/private/preboot/\(envInfo.bmHash)"
        let fileManager = FileManager.default
        
        var value: Int
        let jbFolders: [String]
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: directoryPath)
            jbFolders = contents.filter { $0.hasPrefix("jb-") }
            let jbFolderExists = !jbFolders.isEmpty
            let jbSymlinkPath = "/var/jb"
            let jbSymlinkExists = fileManager.fileExists(atPath: jbSymlinkPath)
            
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
            fatalError("Failed to get contents of directory: \(error.localizedDescription)")
        }
        
        if value == 0 {
            return (0, "")
        } else {
            return (value, "\(directoryPath)/\(jbFolders[0])") // TODO: this probably shouldnt always use 0
        }
    }
    
    func createLoaderDirs() -> Void {
        if (fileExists("/var/mobile/tmp/palera1nloader")) { rmdir("/var/mobile/tmp/palera1nloader") }
        do {
            try FileManager.default.createDirectory(atPath: "/var/tmp/palera1nloader/temp", withIntermediateDirectories: true)
            try FileManager.default.createDirectory(atPath: "/var/tmp/palera1nloader/downloads", withIntermediateDirectories: true)
            try FileManager.default.createDirectory(atPath: "/var/tmp/palera1nloader/logs", withIntermediateDirectories: true)
        } catch {
            log(type: .error, msg: "Failed to create temp directories: \(error)")
        }
     
        
        if let revision = Bundle.main.infoDictionary?["REVISION"] as? String {
            FileManager.default.createFile(atPath: "/var/tmp/palera1nloader/\(revision)", contents: nil)
        } else {
            log(type: .error, msg: "Failed to find revision string")
        }
    }
    
    func prerequisiteChecks() -> Void {
        #if targetEnvironment(simulator)
            envInfo.isSimulator = true
        #endif
        
    
        /// root helper check
        if let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") {
            envInfo.hasHelper = true
            envInfo.helperPath = helper
        }
       
        /// rootless/rootful check
        envInfo.isRootful = helperCmd(["-f"]) == 0 ? false : true
        envInfo.installPrefix = envInfo.isRootful ? "" : "/var/jb"
        
        /// force revert check
        envInfo.hasForceReverted = helperCmd(["-n"]) == 0 ? false : true

        /// get paleinfo and kerninfo flags
        helperCmd(["-g"])
        helperCmd(["-q"])
        
        /// get bmhash
        helperCmd(["-h"])

        /// is installed check
        if fileExists("/.procursus_strapped") || fileExists("/var/jb/.procursus_strapped") {
            envInfo.isInstalled = true
        }
        
        /// device info
        envInfo.systemVersion = "\(local("VERSION_INFO")) \(UIDevice.current.systemVersion)"
        envInfo.systemArch = String(cString: NXGetLocalArchInfo().pointee.name)
        
        /// jb-XXXXXXXX and /var/jb checks
        envInfo.envType = strapCheck().env
        
        /// sileo installed check
        if (fileExists("/Applications/Sileo.app") || fileExists("/var/jb/Applications/Sileo.app") ||
            fileExists("/Applications/Sileo-Nightly.app") || fileExists("/var/jb/Applications/Sileo-Nightly.app")) {
            envInfo.sileoInstalled = true
        }
        
        /// zebra installed check
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
