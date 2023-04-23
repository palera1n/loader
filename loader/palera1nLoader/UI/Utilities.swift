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
        #if targetEnvironment(simulator)
            return (-1, "")
        #else
        let uuid: String
        do {
            uuid = try String(contentsOf: URL(fileURLWithPath: "/private/preboot/active"), encoding: .utf8)
        } catch {
            fatalError("Failed to retrieve UUID: \(error.localizedDescription)")
        }
        let directoryPath = "/private/preboot/\(uuid)"
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
                NSLog("Found jb- folders and /var/jb exists.")
                value = 1
            } else if jbFolderExists && !jbSymlinkExists {
                NSLog("Found jb- folders but /var/jb does not exist.")
                value = 2
            } else {
                NSLog("jb-XXXXXXXX does not exist")
                value = 0
            }
        } catch {
            fatalError("Failed to get contents of directory: \(error.localizedDescription)")
        }
        
        NSLog("[palera1n helper] Strap value: Status: \(value)")
        // if the jb-XXXXXXXX folder does not exist, jbFolders will be an empty array
        // so when we try to access jbFolders[0], we try to read something that does not exist
        // this will prevent it from crashing
        
        if value == 0 {
            return (0, "")
        } else {
            return (value, "\(directoryPath)/\(jbFolders[0])") // TODO: this probably shouldnt always use 0
        }
        #endif
    }
    
    func prerequisiteChecks() -> Void {
        #if targetEnvironment(simulator)
            envInfo.isSimulator = true
            print("[palera1n] Running in simulator")
        #endif
        
        /// root helper check
        if let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") {
            envInfo.hasHelper = true
            envInfo.helperPath = helper
        } else {
            //errAlert(title: "Helper not found", message: "Sideloading is not supported, please jailbreak with palera1n before using.")
        }
       
        /// rootless/rootful check
        envInfo.isRootful = helperCmd(["-f"]) == 0 ? false : true
        envInfo.installPrefix = envInfo.isRootful ? "/" : "/var/jb"
        
        /// force revert check
        envInfo.hasForceReverted = helperCmd(["-n"]) == 0 ? false : true

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
        
        /// for debugging will remove later
        print("installPrefix: \(envInfo.installPrefix)")
        print("envType: \(envInfo.envType)")
        print("systemArch: \(envInfo.systemArch)")
        print("systemVersion: \(envInfo.systemVersion)")
        print("isRootful: \(envInfo.isRootful)")
        print("isInstalled: \(envInfo.isInstalled)")
        print("isSimulator: \(envInfo.isSimulator)")
        print("zebraInstalled: \(envInfo.zebraInstalled)")
        print("sileoInstalled: \(envInfo.sileoInstalled)")
        print("helperPath: \(envInfo.helperPath)")
        print("hasHelper: \(envInfo.hasHelper)")
        print("hasChecked: \(envInfo.hasChecked)")
        print("hasForceReverted: \(envInfo.hasForceReverted)")
    }
}
