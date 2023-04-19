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
    func InfoMenu(rootful: Bool, viewController: UIViewController) -> UIMenu {
        
        var type = "Unknown"
        if rootful {
            type = local("ROOTFUL")
        } else if !rootful {
            type = local("ROOTLESS")
        }

        var installed = local("FALSE")
        if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
            installed = local("TRUE")
        }

        let systemVersion = "\(local("VERSION_INFO")) \(UIDevice.current.systemVersion)"
        let arch = String(cString: NXGetLocalArchInfo().pointee.name)
        let strapValue = Utils().strapCheck()
        
        let doReboot = UIAction(title: "Reboot after revert", image: UIImage(systemName: "power.circle"), state: rebootAfter ? .on : .off) { _ in
            rebootAfter.toggle()
            let infoButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "staroflife.circle"), primaryAction: nil, menu: Utils().InfoMenu(rootful: rootful, viewController: viewController))
            viewController.navigationItem.rightBarButtonItem = infoButton
        }
        
        let hideinstall = UIAction(title: local("HIDE"), image: UIImage(systemName: "eye.slash.circle")) { (_) in
            if !rootful {
                if let strapValue = Utils().strapCheck() {
                    switch strapValue {
                    case 1:
                        warningAlert(title: "Hide Environment", message: "Proceeding will remove the /var/jb symlink and userspace reboot the device, once you open back the loader you will be prompt to add back the symlink to the device to have your environment back.", destructiveButtonTitle: "Proceed", destructiveHandler: {
                            
                            guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
                                errAlert(title: "Could not find helper?", message: "If you've sideloaded this loader app unfortunately you aren't able to use this, please jailbreak with palera1n before proceeding.")
                                return
                            }
                            
                            if (!rootful && FileManager.default.fileExists(atPath: "/var/jb")) {
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
                            print("HELLOOOOOO!!!")
                        })
                        #else
                        errAlert(title: "Unable to proceed", message: "\(local("STRAP_INFO")) \(strapValue)")
                        #endif
                        return
                    }
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
        let menu = UIMenu(title: "\(local("TYPE_INFO")) \(type)\n\(local("INSTALL_INFO")) \(installed)\n\(local("STRAP_INFO")) \(strapValue ?? -1)\n\(local("ARCH_INFO")) \(arch)\n\(systemVersion)", children: [divider, socialsMenu])

        return menu
    }

    // Checks if device is compatable
    func deviceCheck() -> Void {
    #if targetEnvironment(simulator)
        print("[palera1n] Running in simulator")
    #else
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
            errAlert(title: "Could not find helper?", message: "If you've sideloaded this loader app unfortunately you aren't able to use this, please jailbreak with palera1n before proceeding.")
            return
        }
        
        let ret = spawn(command: helper, args: ["-f"], root: true)
        rootful = ret == 0 ? false : true
        inst_prefix = rootful ? "/" : "/var/jb"
        let retRFR = spawn(command: helper, args: ["-n"], root: true)
        let rfr = retRFR == 0 ? false : true
        if rootful {
            if rfr {
                errAlert(title: "Unable to continue", message: "Bootstrapping after using --force-revert is not supported, please rejailbreak to be able to bootstrap again.")
                return
            }
        }
    #endif
    }
    
    func strapCheck() -> Int? {
        #if targetEnvironment(simulator)
            return (-1)
        #else
        let uuid: String
        do {
            uuid = try String(contentsOf: URL(fileURLWithPath: "/private/preboot/active"), encoding: .utf8)
        } catch {
            fatalError("Failed to retrieve UUID: \(error.localizedDescription)")
        }
        let directoryPath = "/private/preboot/\(uuid)"
        let fileManager = FileManager.default
        
        var value: Int?
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: directoryPath)
            let jbFolders = contents.filter { $0.hasPrefix("jb-") }
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
        
        NSLog("[palera1n helper] Strap value: Status: \(value ?? -1)") // -1 is a default value in case `value` is nil
        return value
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
            var pre = "/var/jb"
            if rootful { pre = "/"}
            let alertController = whichAlert(title: local("UTIL_CELL"))
            
            let actions: [(title: String, imageName: String, handler: () -> Void)] = [
                (title: local("RESPRING"), imageName: "arrow.clockwise.circle", handler: { spawn(command: "\(pre)/usr/bin/sbreload", args: [], root: true)}),
                (title: local("US_REBOOT"), imageName: "power.circle", handler: { spawn(command: "\(pre)/usr/bin/launchctl", args: ["reboot", "userspace"], root: true)}),
                (title: local("UICACHE"), imageName: "xmark.circle", handler: { spawn(command: "\(pre)/usr/bin/uicache", args: ["-a"], root: true)}),
                (title: local("DAEMONS"), imageName: "play.circle", handler: { spawn(command: "\(pre)/bin/launchctl", args: ["bootstrap", "system", "/var/jb/Library/LaunchDaemons"], root: true)}),
                (title: local("MOUNT"), imageName: "folder.circle", handler: { spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true); spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true) }),
                (title: local("TWEAKS"), imageName: "iphone.circle", handler: {
                    if rootful {spawn(command: "/etc/rc.d/substitute-launcher", args: [], root: true)}
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
    
}
