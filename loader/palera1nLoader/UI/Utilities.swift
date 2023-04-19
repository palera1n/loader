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
    func InfoMenu(viewController: UIViewController) -> UIMenu {
        let type = envInfo.isRootful ? local("ROOTFUL") : local("ROOTLESS")
        let installed = envInfo.isInstalled ? local("TRUE") : local("FALSE")
        let systemVersion = envInfo.systemVersion
        let arch = envInfo.systemArch
        let strapValue = envInfo.envType
        
        let doReboot = UIAction(title: "Reboot after revert", image: UIImage(systemName: "power.circle"), state: envInfo.rebootAfter ? .on : .off) { _ in
            envInfo.rebootAfter.toggle()
            let infoButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "staroflife.circle"), primaryAction: nil, menu: Utils().InfoMenu(viewController: viewController))
            viewController.navigationItem.rightBarButtonItem = infoButton
        }
        
        let hideinstall = UIAction(title: local("HIDE"), image: UIImage(systemName: "eye.slash.circle")) { (_) in
            if !envInfo.isRootful {
                let strapValue = Utils().strapCheck().env 
                switch strapValue {
                case 1:
                    warningAlert(title: "Hide Environment", message: "Proceeding will remove the /var/jb symlink and userspace reboot the device, once you open back the loader you will be prompt to add back the symlink to the device to have your environment back.", destructiveButtonTitle: "Proceed", destructiveHandler: {
                        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
                            errAlert(title: "Could not find helper?", message: "If you've sideloaded this loader app unfortunately you aren't able to use this, please jailbreak with palera1n before proceeding.")
                            return
                        }
                        
                        if (!envInfo.isRootful && FileManager.default.fileExists(atPath: "/var/jb")) {
                            do { try FileManager.default.removeItem(at: URL(fileURLWithPath: "/var/jb")) }
                            catch { NSLog("[palera1n helper] Failed with error \(error.localizedDescription)") }
                        }
                        
                        let ret = spawn(command: helper, args: ["-d"], root: true)
                        if (ret != 0) {
                            return
                        }
                    })
                default:
                    #if targetEnvironment(simulator)
                    warningAlert(title: "Hide Environment", message: "Proceeding will remove the /var/jb symlink and userspace reboot the device, once you open back the loader you will be prompt to add back the symlink to the device to have your environment back.", destructiveButtonTitle: "Proceed", destructiveHandler: {
                    })
                    #else
                    errAlert(title: "Unable to proceed", message: "\(local("STRAP_INFO")) \(strapValue)")
                    #endif
                    return
                }
            } else {
                errAlert(title: "Unable to proceed", message: "You may not use this button if you're on a non rootless jailbreak.")
                return
            }
        }

        let discord = UIAction(title: local("DISCORD"), image: UIImage(systemName: "arrow.up.forward.app")) { (_) in
            UIApplication.shared.open(URL(string: "https://discord.gg/palera1n")!)
        }

        let twitter = UIAction(title: local("TWITTER"), image: UIImage(systemName: "arrow.up.forward.app")) { (_) in
            UIApplication.shared.open(URL(string: "https://twitter.com/palera1n")!)
        }

        let website = UIAction(title: local("WEBSITE"), image: UIImage(systemName: "arrow.up.forward.app")) { (_) in
            UIApplication.shared.open(URL(string: "https://palera.in")!)
        }

        let discordSubMenu = UIMenu(options: .displayInline, children: [discord])
        let twitterSubMenu = UIMenu(options: .displayInline, children: [twitter])
        let websiteSubMenu = UIMenu(options: .displayInline, children: [website])
        
        let divider = UIMenu(title: "", options: .displayInline, children: [doReboot, hideinstall])
        
        let socialsMenu = UIMenu(title: local("SOCIALS"), children: [discordSubMenu, twitterSubMenu, websiteSubMenu])
        let menu = UIMenu(title: "\(local("TYPE_INFO")) \(type)\n\(local("INSTALL_INFO")) \(installed)\n\(local("STRAP_INFO")) \(strapValue)\n\(local("ARCH_INFO")) \(arch)\n\(systemVersion)", children: [divider, socialsMenu])

        return menu
    }
    
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
        return (value, "\(directoryPath)/\(jbFolders[0])") // TODO: this probably shouldnt always use 0
        #endif
    }
    
    // Opens an alert controller with actions to open an app
    @objc func openersTapped() {
        DispatchQueue.main.async {
            let alertController = whichAlert(title: local("OPENER_MSG"))
            let actions: [(title: String, imageName: String, handler: () -> Void)] = [
                (title: local("OPENER_SILEO"), imageName: "arrow.up.forward.app", handler: {
                    if (openApp("org.coolstar.SileoStore")){}else{_ = openApp("org.coolstar.SileoNightly")}
                }),
                (title: local("OPENER_ZEBRA"), imageName: "arrow.up.forward.app", handler: {_ = openApp("xyz.willy.Zebra")}),
                (title: local("OPENER_TH"), imageName: "arrow.up.forward.app", handler: {_ = openApp("com.opa334.trollstorepersistencehelper")})
            ]
            
            for action in actions {
                let alertAction = UIAlertAction(title: action.title, style: .default) { (_) in action.handler() }
                alertAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
                if let image = UIImage(systemName: action.imageName) { alertAction.setValue(image, forKey: "image") }
                alertController.addAction(alertAction)
            }
            
            alertController.addAction(UIAlertAction(title: local("CANCEL"), style: .cancel) { (_) in})
            global.present(alertController, animated: true, completion: nil)
        }
    }
    
    // Opens an alert controller with actions to useful functions
    @objc func actionsTapped() {
        DispatchQueue.main.async {
            let pre = envInfo.installPrefix
            let alertController = whichAlert(title: local("UTIL_CELL"))
            
            let actions: [(title: String, imageName: String, handler: () -> Void)] = [
                (title: local("RESPRING"), imageName: "arrow.clockwise.circle", handler: { spawn(command: "\(pre)/usr/bin/sbreload", args: [], root: true)}),
                (title: local("US_REBOOT"), imageName: "power.circle", handler: { spawn(command: "\(pre)/usr/bin/launchctl", args: ["reboot", "userspace"], root: true)}),
                (title: local("UICACHE"), imageName: "xmark.circle", handler: { spawn(command: "\(pre)/usr/bin/uicache", args: ["-a"], root: true)}),
                (title: local("DAEMONS"), imageName: "play.circle", handler: { spawn(command: "\(pre)/bin/launchctl", args: ["bootstrap", "system", "/var/jb/Library/LaunchDaemons"], root: true)}),
                (title: local("MOUNT"), imageName: "folder.circle", handler: { spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true); spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true) }),
                (title: local("TWEAKS"), imageName: "iphone.circle", handler: {
                    if envInfo.isRootful {spawn(command: "/etc/rc.d/substitute-launcher", args: [], root: true)}
                    else {spawn(command: "/var/jb/usr/libexec/ellekit/loader", args: [], root: true)}
                })
            ]
            
            for action in actions {
                let alertAction = UIAlertAction(title: action.title, style: .default) { (_) in action.handler() }
                alertAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
                if let image = UIImage(systemName: action.imageName) { alertAction.setValue(image, forKey: "image") }
                alertController.addAction(alertAction)
            }
            
            alertController.addAction(UIAlertAction(title: local("CANCEL"), style: .cancel) { (_) in})
            global.present(alertController, animated: true, completion: nil)
        }
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
