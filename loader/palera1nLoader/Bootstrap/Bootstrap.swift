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
    
    // Created palera1n defaults sources file for Sileo/Zebra
    func defaultSources(_ packageManager: String) -> Void {
        let zebraPath = URL(string: "/var/mobile/Library/Application Support/xyz.willy.Zebra/palera1n.list")!
        let sileoPath = URL(string: envInfo.installPrefix)!.appendingPathComponent("etc/apt/sources.list.d/palera1n.sources")
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let tempURL = documentsURL.appendingPathComponent("temp_sources")
        
        let CF = Int(floor(kCFCoreFoundationVersionNumber / 100) * 100)

        var zebraSourcesFile = "deb https://repo.palera.in/\n"
        var sileoSourcesFile = """
        Types: deb\nURIs: https://repo.getsileo.app/\nSuites: ./\nComponents:\n
        Types: deb\nURIs: https://repo.palera.in/\nSuites: ./\nComponents:\n\n
        """
        
        if (envInfo.isRootful) {
            sileoSourcesFile += "Types: deb\nURIs: https://strap.palera.in/\nSuites: iphoneos-arm64/\(CF)\nComponents: main\n\n"
            zebraSourcesFile += "deb https://strap.palera.in/ iphoneos-arm64/\(CF) main\n"
        } else {
            sileoSourcesFile += "Types: deb\nURIs: https://ellekit.space/\nSuites: ./\nComponents:\n\n"
            zebraSourcesFile += "deb https://ellekit.space/ ./\n"
        }
        
        switch(packageManager) {
        case "sileo.deb":
            try? sileoSourcesFile.write(to: tempURL, atomically: true, encoding: String.Encoding.utf8)
            spawn(command: "\(envInfo.installPrefix)/usr/bin/mv", args: [tempURL.path, sileoPath.path], root: true)
        case "zebra.deb":
            try? zebraSourcesFile.write(to: tempURL, atomically: true, encoding: String.Encoding.utf8)
            spawn(command: "\(envInfo.installPrefix)/usr/bin/mv", args: [tempURL.path, zebraPath.path], root: true)
        default:
            print("[palera1n] Unknown or Unsupported Package Manager")
        }
    }
    

    func installDebian(deb: String, withStrap: Bool, completion: @escaping (String?, Int?) -> Void) {
        var ret = spawn(command: "\(envInfo.installPrefix)/usr/bin/dpkg", args: ["-i", deb], root: true)
        if (ret != 0) {
            completion(local("DPKG_ERROR"), ret)
            return
        }
        
        ret = spawn(command: "\(envInfo.installPrefix)/usr/bin/uicache", args: ["-a"], root: true)
        if (ret != 0) {
            completion(local("UICACHE_ERROR"), ret)
            return
        }
        
        defaultSources(URL(string: deb)!.lastPathComponent)
        cleanUp()
        completion(local("INSTALL_DONE"), 0)
        return
    }
    
    
    func installBootstrap(tar: String, deb: String, completion: @escaping (String?, Int?) -> Void) {
        spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
        if envInfo.isRootful {
            spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)
        }
        
        var ret = helperCmd(["-i", tar])
        if (ret != 0) {
            completion(local("STRAP_ERROR"), ret)
            return
        }
        
        spawn(command: "\(envInfo.installPrefix)/usr/bin/chmod", args: ["4755", "\(envInfo.installPrefix)/usr/bin/sudo"], root: true)
        spawn(command: "\(envInfo.installPrefix)/usr/bin/chown", args: ["root:wheel", "\(envInfo.installPrefix)/usr/bin/sudo"], root: true)
        
        ret = spawn(command: "\(envInfo.installPrefix)/usr/bin/sh", args: ["\(envInfo.installPrefix)/prep_bootstrap.sh"], root: true)
        if (ret != 0) {
            completion(local("STRAP_ERROR"), ret)
            return
        }
        
        completion(local("INSTALL_DONE"), 0)
        return
    }
    
    
    // Reverting/Removing jailbreak, wipes /var/jb
    func revert() -> Void {
        if !envInfo.isRootful {
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
            DispatchQueue.main.async {
                global.presentedViewController!.dismiss(animated: true) {
                    let loadingAlert = UIAlertController(title: nil, message: local("REMOVING"), preferredStyle: .alert)
                    let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
                    loadingAlert.view.addSubview(loadingIndicator)
                    loadingIndicator.hidesWhenStopped = true
                    loadingIndicator.startAnimating()
                    global.present(loadingAlert, animated: true, completion: nil)
                }
            }
            
            DispatchQueue.global(qos: .utility).async {
                let apps = try? FileManager.default.contentsOfDirectory(atPath: "/var/jb/Applications")
                for app in apps ?? [] {
                    if app.hasSuffix(".app") {
                        let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-u", "/var/jb/Applications/\(app)"], root: true)
                        if ret != 0 {errAlert(title: "Failed to unregister \(app)", message: "Status: \(ret)"); return}
                    }
                }
                
                let ret = helperCmd(["-r"])
                if ret != 0 {
                    errAlert(title: local("REVERT_FAIL"), message: "Status: \(ret)")
                    return
                }
                    
                if (envInfo.rebootAfter) {
                    _ = helperCmd(["-d"])
                } else {
                    errAlert(title: local("REVERT_DONE"), message: local("CLOSE_APP"))
                }
            }
        }
    }
}

