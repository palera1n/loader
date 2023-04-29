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
        deleteFile(file: "libkrw0-tfp0.deb")
        deleteFile(file: "bootstrap.tar")
        
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
        
        
        // non-fatal error here on rootful (non-breaking, non-issue)
        do {
            let tmp = URL(string: NSTemporaryDirectory())!
            let tmpFile = try FileManager.default.contentsOfDirectory(at: tmp, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for url in tmpFile {try FileManager.default.removeItem(at: url)}}
        catch {
            log(type: .error, msg: "Error removing temp files: \(error)" )
            return
        }
    }
    
    // Created palera1n defaults sources file for Sileo/Zebra
    func defaultSources(_ packageManager: String) -> Void {
        //let zebraPath = URL(string: "/var/mobile/Library/Application Support/xyz.willy.Zebra/palera1n.list")!
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
        //case "zebra.deb":
            // need to fix
            //try? zebraSourcesFile.write(to: tempURL, atomically: true, encoding: String.Encoding.utf8)
            //spawn(command: "\(envInfo.installPrefix)/usr/bin/mv", args: [tempURL.path, zebraPath.path], root: true)
        default:
            log(type: .warning, msg: "Unknown or Unsupported Package Manager" )
        }
    }
    
    func installDebian(deb: String, completion: @escaping (String?, Int?) -> Void) {
        var ret = spawn(command: "\(envInfo.installPrefix)/usr/bin/dpkg", args: ["-i", deb], root: true)
        if (ret != 0) {
            completion(local("DPKG_ERROR"), ret)
            return
        }

        ret = spawn(command: "\(envInfo.installPrefix)/usr/bin/apt-get", args: ["install", "-f", "-y", "--allow-unauthenticated"], root: true)
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
    
    func mv0(_ from: String,_ to: String) -> Void {
        spawn(command: "/cores/binpack/bin/mv", args: ["-f", from, to], root: true)
    }
    
    
    func installBootstrap(tar: String, deb: String, completion: @escaping (String?, Int?) -> Void) {
        spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
        if envInfo.isRootful {
            spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)
        }
        
        deleteFile(file: "bootstrap.tar")
        var ret = spawn(command: "/cores/binpack/usr/bin/zstd", args: ["-d", tar, "-o", docsFile(file: "bootstrap.tar")], root: true)
        if (ret != 0) {
            completion(local("STRAP_ERROR"), ret)
            return
        }
        
        if (envInfo.isRootful) {
            ret = spawn(command: "/cores/binpack/usr/bin/tar", args: ["-xkf", docsFile(file: "bootstrap.tar"), "-C", "/", "--preserve-permissions"], root: true)
        } else {
            var randomString = ""

            for _ in 0..<8 {
                let randomValue = Int.random(in: 1...3)
                let char: String
                switch randomValue {
                case 1:
                    char = String(UnicodeScalar(Int.random(in: 65...90))!)
                case 2:
                    char = String(UnicodeScalar(Int.random(in: 97...122))!)
                default:
                    char = String(Int.random(in: 0...9))
                }
                randomString.append(char)
            }
            let prefix = "/private/preboot/\(envInfo.bmHash)"
            
            spawn(command: "/cores/binpack/bin/rm", args: ["-rf", "/var/jb"], root: true)
            spawn(command: "/cores/binpack/bin/rm", args: ["-rf", "/private/preboot/\(envInfo.bmHash)/jb-*"], root: true)

            
            ret = spawn(command: "/cores/binpack/usr/bin/tar", args: ["-xkf", docsFile(file: "bootstrap.tar"), "-C", prefix, "--preserve-permissions"], root: true)
            
            mv0("\(prefix)/var", "\(prefix)/jb-\(randomString)")
            mv0("\(prefix)/jb-\(randomString)/jb", "\(prefix)/jb-\(randomString)/procursus")

            spawn(command: "/cores/binpack/bin/ln", args: ["-s", "\(prefix)/jb-\(randomString)/procursus", "/var/jb"], root: true)
            spawn(command: "/cores/binpack/usr/sbin/chown", args: ["0:0", "/var/jb"], root: true)
            spawn(command: "/cores/binpack/bin/chmod", args: ["4755", "/var/jb"], root: true)

        }
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
        
        if !envInfo.isRootful {
            let libkrwPath = docsFile(file: "libkrw0-tfp0.deb")
            ret = spawn(command: "/var/jb/usr/bin/dpkg", args: ["-i", libkrwPath], root: true)
            if (ret != 0) {
                completion(local("DPKG_ERROR"), ret)
                return
            }
        }
         
        let debPath = docsFile(file: deb)
        ret = spawn(command: "\(envInfo.installPrefix)/usr/bin/dpkg", args: ["-i", debPath], root: true)
        if (ret != 0) {
            completion(local("DPKG_ERROR"), ret)
            return
        }
         
        ret = spawn(command: "\(envInfo.installPrefix)/usr/bin/apt-get", args: ["install", "-f", "-y", "--allow-unauthenticated"], root: true)
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
        if envInfo.isRootful { spawn(command: "/usr/bin/rm", args: ["/etc/apt/sources.list.d/procursus.sources"], root: true) }
        completion(local("INSTALL_DONE"), 0)
        return
    }
    
    // Reverting/Removing jailbreak, wipes /var/jb
    func revert(viewController: UIViewController) -> Void {
        if !envInfo.isRootful {
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
            let alert = UIAlertController.spinnerAlert("REMOVING")
            viewController.present(alert, animated: true)
            
            let apps = try? FileManager.default.contentsOfDirectory(atPath: "/var/jb/Applications")
            for app in apps ?? [] {
                if app.hasSuffix(".app") {
                    let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-u", "/var/jb/Applications/\(app)"], root: true)
                    if ret != 0 {
                        let errorAlert = UIAlertController.error(title: "Failed to unregister \(app)", message: "Status: \(ret)");
                        alert.dismiss(animated: true) {
                            viewController.present(errorAlert, animated: true)
                        }
                        return
                    }
                }
            }
            
            let ret = helperCmd(["-r"])
            if ret != 0 {
                let errorAlert = UIAlertController.error(title: local("REVERT_FAIL"), message: "Status: \(ret)")
                alert.dismiss(animated: true) {
                    viewController.present(errorAlert, animated: true)
                }
                return
            }
                
            if (envInfo.rebootAfter) {
                helperCmd(["-d"])
            } else {
                let errorAlert = UIAlertController.error(title: local("REVERT_DONE"), message: local("CLOSE_APP"))
                alert.dismiss(animated: true) {
                    viewController.present(errorAlert, animated: true)
                }
            }
        }
    }
}

