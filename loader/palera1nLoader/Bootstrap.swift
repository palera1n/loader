//
//  Bootstrap.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/12/23.
//

import Foundation
import UIKit

func cleanUp() -> Void {
    deleteFile(file: "sileo.deb")
    deleteFile(file: "zebra.deb")
    deleteFile(file: "bootstrap.tar")
    
    URLCache.shared.removeAllCachedResponses()
    URLCache.shared.diskCapacity = 0
    URLCache.shared.memoryCapacity = 0
    
    do {
        let tmp = URL(string: NSTemporaryDirectory())!
        let tmpFile = try FileManager.default.contentsOfDirectory(at: tmp, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        for url in tmpFile {try FileManager.default.removeItem(at: url)}}
    catch {
        NSLog("[palera1n] Error removing temp files: \(error)")
        return
    }
}

func installDeb(_ file: String,_ rootful: Bool) -> Void {
    let group = DispatchGroup()
    group.enter()
    DispatchQueue.global(qos: .default).async {
        download("\(file).deb", rootful)
        group.leave()
    }
    group.wait()
    spinnerAlert("INSTALLING", start: true)
    let inst_prefix = rootful ? "" : "/var/jb"
    let deb = "\(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(file).deb").path)" // gross
    
    var ret = spawn(command: "\(inst_prefix)/usr/bin/dpkg", args: ["-i", deb], root: true)
    if (ret != 0) {
        spinnerAlert("INSTALLING", start: false)
        errAlert(title: local("DPKG_ERROR"), message: "Status: \(ret)")
        return
    }
    
    ret = spawn(command: "\(inst_prefix)/usr/bin/uicache", args: ["-a"], root: true)
    if (ret != 0) {
        spinnerAlert("INSTALLING", start: false)
        errAlert(title: local("UICACHE_ERROR"), message: "Status: \(ret)")
        return
        
    }
    sleep(1)
    spinnerAlert("INSTALLING", start: false)
    errAlert(title: local("INSTALL_DONE"), message: local("ENJOY"))
}
        
    
func bootstrap(_ rootful: Bool) -> Void {
    guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
        print("[palera1n] Could not find helper?")
        return
    }
    let inst_prefix = rootful ? "/" : "/var/jb"
    let tar = "\(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("bootstrap.tar").path)"

    let group = DispatchGroup()
    group.enter()
    DispatchQueue.global(qos: .default).async {
        download("bootstrap.tar", rootful)
        group.leave()
    }
    group.wait()
    
    spinnerAlert("INSTALLING", start: true)
    spawn(command: "/sbin/mount", args: ["-uw", "/preboot"], root: true)
    if rootful { spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)}
    var ret = spawn(command: helper, args: ["-i", tar], root: true)
    spawn(command: "\(inst_prefix)/usr/bin/chmod", args: ["4755", "\(inst_prefix)/usr/bin/sudo"], root: true)
    spawn(command: "\(inst_prefix)/usr/bin/chown", args: ["root:wheel", "\(inst_prefix)/usr/bin/sudo"], root: true)
    
    if (ret != 0) {
        spinnerAlert("INSTALLING", start: false)
        errAlert(title: local("STRAP_ERROR"), message: "Status: \(ret)")
        return
    }
    
    ret = spawn(command: "\(inst_prefix)/usr/bin/sh", args: ["\(inst_prefix)/prep_bootstrap.sh"], root: true)
    if (ret != 0) {
        spinnerAlert("INSTALLING", start: false)
        errAlert(title: local("STRAP_ERROR"), message: "Status: \(ret)")
        return
    }
        
    // add zebra sources
   
    spinnerAlert("INSTALLING", start: false)
}

func combo(_ file: String,_ rootful: Bool) -> Void {
    DispatchQueue.global(qos: .utility).async { [] in
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .default).async {
            bootstrap(rootful)
            group.leave()
        }
        group.wait()
        installDeb(file, rootful)
    }
}

func revert(_ reboot: Bool) -> Void {
    guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
        print("[palera1n] Could not find helper?");return
    }
    
    let ret = spawn(command: helper, args: ["-f"], root: true)
    let rootful = ret == 0 ? false : true
    if !rootful {
        spinnerAlert("REMOVING", start: true)
        DispatchQueue.global(qos: .utility).async {
            let apps = try? FileManager.default.contentsOfDirectory(atPath: "/var/jb/Applications")
            for app in apps ?? [] {
                if app.hasSuffix(".app") {
                    let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-u", "/var/jb/Applications/\(app)"], root: true)
                    if ret != 0 {errAlert(title: "Failed to unregister \(app)", message: "Status: \(ret)"); return}
                }
            }
            
            let ret = spawn(command: helper, args: ["-r"], root: true)
            if ret != 0 {
                errAlert(title: local("REVERT_FAIL"), message: "Status: \(ret)")
                print("[revert] Failed to remove jailbreak: \(ret)")
                return
            }
                
            sleep(1)
            if (reboot) {
                spawn(command: helper, args: ["-d"], root: true)
            } else {
                spinnerAlert("REMOVING", start: false)
                errAlert(title: local("REVERT_DONE"), message: local("CLOSE_APP"))
            }
            
        }
    }
}
