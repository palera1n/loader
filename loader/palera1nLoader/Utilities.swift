//
//  Utilities.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/16/23.
//

import Foundation
import UIKit
import Toast

class Utils {
    
    
    // Presents our toast alert
    func showToast(_ isError: Bool,_ title: String,_ subtitle: String = "") {
        let toastConfig = ToastConfiguration(
            direction: .top,
            autoHide: true,
            enablePanToClose: false,
            displayTime: 2.5,
            animationTime: 0.2
        )
        
        DispatchQueue.main.async {
            let check = UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 48)))!.withTintColor(UIColor(red: 0.00, green: 0.65, blue: 0.81, alpha: 1.00), renderingMode: .alwaysOriginal)
            let cross = UIImage(systemName: "xmark.circle", withConfiguration: UIImage.SymbolConfiguration(font: .systemFont(ofSize: 48)))!.withTintColor(UIColor(red: 0.96, green: 0.28, blue: 0.25, alpha: 1.00), renderingMode: .alwaysOriginal)
            let image: UIImage = isError ? cross : check
            
            if (global.presentedViewController != nil) {
                global.presentedViewController!.dismiss(animated: true) {
                    if (subtitle != "") {
                        let toast = Toast.default(image: image, title: title, subtitle: subtitle, config: toastConfig)
                        toast.enableTapToClose()
                        toast.show()
                    } else {
                        let toast = Toast.default(image: image, title: title, config: toastConfig)
                        toast.enableTapToClose()
                        toast.show()
                    }
                }
            } else {
                if (subtitle != "") {
                    let toast = Toast.default(image: image, title: title, subtitle: subtitle, config: toastConfig)
                    toast.enableTapToClose()
                    toast.show()
                } else {
                    let toast = Toast.default(image: image, title: title, config: toastConfig)
                    toast.enableTapToClose()
                    toast.show()
                }
            }
        }
    }
    
    
    // Checks if device is compatable
    func deviceCheck() -> Void {
#if targetEnvironment(simulator)
        print("[palera1n] Running in simulator")
#else
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
            //errAlert(title: "Could not find helper?", message: "If you've sideloaded this loader app unfortunately you aren't able to use this, please jailbreak with palera1n before proceeding.")
            return
        }
        
        let ret = spawn(command: helper, args: ["-f"], root: true)
        rootful = ret == 0 ? false : true
        inst_prefix = rootful ? "/" : "/var/jb"
        let retRFR = spawn(command: helper, args: ["-n"], root: true)
        let rfr = retRFR == 0 ? false : true
        if rootful {
            if rfr {
                //errAlert(title: "Unable to continue", message: "Bootstrapping after using --force-revert is not supported, please rejailbreak to be able to bootstrap again.")
                return
            }
        }
#endif
    }
    
    
    // Opens an alert controller with actions to open an app
    @objc func openersTapped() {
        let alertController = whichAlert(title: local("OPENER_MSG"))
        let actions: [(title: String, imageName: String, handler: () -> Void)] = [
            (title: local("OPENER_SILEO"), imageName: "arrow.up.forward.app", handler: {
                if (openApp("org.coolstar.SileoStore")){}else{
                    let ret = openApp("org.coolstar.SileoNightly")
                    if (!ret) {
                        self.showToast(true, "Failed to open Sileo")
                    }
                }
            }),
            (title: local("OPENER_ZEBRA"), imageName: "arrow.up.forward.app", handler: {
                let ret = openApp("xyz.willy.Zebra")
                if (!ret) {
                    self.showToast(true, "Failed to open Zebra")
                }
            }),
            (title: local("OPENER_TH"), imageName: "arrow.up.forward.app", handler: {
                let ret = openApp("com.opa334.trollstorepersistencehelper")
                if (!ret) {
                    self.showToast(true, "Failed to open TrollHelper")
                }
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
    
    
    // Opens an alert controller with actions to useful functions
    @objc func actionsTapped() {
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
