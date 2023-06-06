//
//  Utilities.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/16/23.
//

import Foundation
import UIKit
import MachO
import Extras

class Utils {
    
//MARK: - Check for installation in jb-* and environment type
    
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
            #if !targetEnvironment(simulator)
            fatalError("Failed to get contents of directory: \(error.localizedDescription)")
            #else
            return (-1, "")
            #endif
        }
        if value == 0 {
            return (0, "")
        } else {
            envInfo.jbFolder = "\(directoryPath)/\(jbFolders[0])"
            return (value, "\(directoryPath)/\(jbFolders[0])") // TODO: this probably shouldnt always use 0
        }
    }
    

//MARK: - Preparing loader for use, creating files, etc

    func createLoaderDirs() -> Void {
        if (!fileExists("/var/mobile/Library/palera1n")) {
            do {
                try FileManager.default.createDirectory(atPath: "/var/mobile/Library/", withIntermediateDirectories: true)
                try FileManager.default.createDirectory(atPath: "/var/mobile/Library/palera1n/temp", withIntermediateDirectories: true)
                try FileManager.default.createDirectory(atPath: "/var/mobile/Library/palera1n/downloads", withIntermediateDirectories: true)
                try FileManager.default.createDirectory(atPath: "/var/mobile/Library/palera1n/logs", withIntermediateDirectories: true)
            } catch {
                log(type: .error, msg: "Failed to create temp directories: \(error)")
            }
        }
     
        if let revision = Bundle.main.infoDictionary?["REVISION"] as? String {
            FileManager.default.createFile(atPath: "/var/mobile/Library/palera1n/.revision-\(revision)", contents: nil)
        } else {
            log(type: .error, msg: "Failed to find revision string")
        }
    }
    
    
    // Sets all info in envInfo
    func prerequisiteChecks() -> Void {
        createHelperLink()
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
        envInfo.envType = strapCheck().env
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

// Revert/Removes jailbreak install on rootless devices
func revert(viewController: UIViewController) -> Void {
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
 
// Create Symlink for helper
func createHelperLink() {
    let path = "/var/mobile/Library/palera1n/helper"
    if (fileExists("/cores/jbloader")) {
        if (fileExists(path)) {
            log(type: .info, msg: "helper symlink already exists.")
        } else {
            let ret = bp_ln("/cores/jbloader", path)
            if (ret != 0) { log(type: .fatal, msg: "Failed to create helper symlink.") }
            chmod(path, 0755)
        }
    } else {
        log(type: .fatal, msg: "Failed to find jbloader")
    }
}

// Find and open TrollStore Helper
func openTrollHelper() -> Void {
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
