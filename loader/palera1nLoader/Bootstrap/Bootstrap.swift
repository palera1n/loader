//
//  Bootstrap.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/12/23.
//

import Foundation
import UIKit

class bootstrap {
    
    @discardableResult func bp_rm(_ file: String) -> Int {
        return spawn(command: "/cores/binpack/bin/rm", args: ["-rf", file], root: true)
    }
    
    @discardableResult func bp_bsdtar(_ args: [String]) -> Int {
        return spawn(command: "/cores/binpack/usr/bin/tar", args: args, root: true)
    }
    
    @discardableResult func bp_ln(_ target: String,_ src: String) -> Int {
        return spawn(command: "/cores/binpack/bin/ln", args: ["-s", target, src], root: true)
    }
    
    @discardableResult func bp_chown(_ owner: Int,_ group: Int,_ file: String) -> Int {
        return spawn(command: "/cores/binpack/usr/sbin/chown", args: ["\(owner):\(group)", file], root: true)
    }
    
    @discardableResult func bp_chmod(_ bits: Int,_ file: String) -> Int {
        return spawn(command: "/cores/binpack/bin/chmod", args: [String(bits), "/var/jb"], root: true)
    }

    @discardableResult func bp_mv(_ from: String,_ to: String) -> Int {
        return spawn(command: "/cores/binpack/bin/mv", args: ["-f", from, to], root: true)
    }

    // Ran after bootstrap/deb install
    func cleanUp() -> Void {
        deleteFile(file: "sileo.deb")
        deleteFile(file: "zebra.deb")
        deleteFile(file: "libkrw0-tfp0.deb")
        deleteFile(file: "bootstrap.tar")
        
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
        
        do {
            let tmp = URL(string: NSTemporaryDirectory())!
            let tmpFile = try FileManager.default.contentsOfDirectory(at: tmp, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for url in tmpFile {try FileManager.default.removeItem(at: url)}}
        catch {
            return
        }
    }
    
    // Created palera1n defaults sources file for Sileo/Zebra
    func defaultSources(for packageManager: String) {
        let zebraPath = "/var/mobile/Library/Application Support/xyz.willy.Zebra/sources.list"
        let sileoPath = "\(envInfo.installPrefix)/etc/apt/sources.list.d/palera1n.sources"

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let tempURL = documentsURL.appendingPathComponent("temp_sources")

        var zebraSourcesFile = "deb https://repo.palera.in/ ./\ndeb https://getzbra.com/repo ./\n"
        var sileoSourcesFile = "Types: deb\nURIs: https://repo.palera.in/\nSuites: ./\nComponents:\n\n"

        if envInfo.isRootful {
            bp_rm("/etc/apt/sources.list.d/procursus.sources")
            sileoSourcesFile += "Types: deb\nURIs: https://strap.palera.in/\nSuites: iphoneos-arm64/\(envInfo.CF)\nComponents: main\n"
            zebraSourcesFile += "deb https://strap.palera.in/ iphoneos-arm64/\(envInfo.CF) main\n"
        } else {
            sileoSourcesFile += "Types: deb\nURIs: https://ellekit.space/\nSuites: ./\nComponents:\n\n"
            zebraSourcesFile += "deb https://ellekit.space/ ./\ndeb https://apt.procurs.us/ \(envInfo.CF) main\n"
        }

        switch packageManager {
        case "sileo.deb":
            do {
                try sileoSourcesFile.write(to: tempURL, atomically: true, encoding: .utf8)
                bp_mv(tempURL.path, sileoPath)
            } catch {
                log(type: .warning, msg: "Error writing Sileo sources file: \(error)")
            }
        case "zebra.deb":
            bp_rm(zebraPath)
            do {
                try zebraSourcesFile.write(to: tempURL, atomically: true, encoding: .utf8)
                bp_mv(tempURL.path, zebraPath)
            } catch {
                log(type: .warning, msg: "Error writing Zebra sources file: \(error)")
            }
        default:
            log(type: .warning, msg: "Unknown or unsupported package manager: \(packageManager)")
        }
    }

    func installDebian(deb: String, completion: @escaping (String?, Int?) -> Void) {
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
        
        defaultSources(for: URL(string: deb)!.lastPathComponent)
        cleanUp()
        completion(local("INSTALL_DONE"), 0)
        return
    }
    
    func randomStr() -> String {
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
        return randomString
    }
    
    func installBootstrap(tar: String, deb: String, completion: @escaping (String?, Int?) -> Void) {
        // mounts
        spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
        if envInfo.isRootful { spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true) }

        // extract zstd strap
        deleteFile(file: "bootstrap.tar")
        var ret = spawn(command: "/cores/binpack/usr/bin/zstd", args: ["-d", tar, "-o", docsFile(file: "bootstrap.tar")], root: true)
        if (ret != 0) {
            completion(local("STRAP_ERROR"), ret)
            return
        }
        
        // install bootstrap
        if (envInfo.isRootful) {
            ret = bp_bsdtar(["-xkf", docsFile(file: "bootstrap.tar"), "-C", "/", "--preserve-permissions"])
        } else {
            let prefix = "/private/preboot/\(envInfo.bmHash)"
            let randomString = randomStr()
            bp_rm("/var/jb")
            bp_rm("\(prefix)/jb-*")
            
            ret = bp_bsdtar(["-xkf", docsFile(file: "bootstrap.tar"), "-C", prefix, "--preserve-permissions"])

            bp_mv("\(prefix)/var", "\(prefix)/jb-\(randomString)")
            bp_mv("\(prefix)/jb-\(randomString)/jb", "\(prefix)/jb-\(randomString)/procursus")
            
            bp_ln("\(prefix)/jb-\(randomString)/procursus", "/var/jb")
            bp_chown(0, 0, "/var/jb")
            bp_chmod(755, "/var/jb")
        }
        
        if (ret != 0) {
            completion(local("STRAP_ERROR"), ret)
            return
        }
        
        // prep bootstrap
        ret = spawn(command: "\(envInfo.installPrefix)/usr/bin/sh", args: ["\(envInfo.installPrefix)/prep_bootstrap.sh"], root: true)
        if (ret != 0) {
            completion(local("STRAP_ERROR"), ret)
            return
        }
        
        // install libkrw0-tfp0
        let libkrwPath = docsFile(file: "libkrw0-tfp0.deb")
        ret = spawn(command: "\(envInfo.installPrefix)/usr/bin/dpkg", args: ["-i", libkrwPath], root: true)
        if (ret != 0) {
            completion(local("DPKG_ERROR"), ret)
            return
        }
        
        // install package manager
        let debPath = docsFile(file: deb)
        ret = spawn(command: "\(envInfo.installPrefix)/usr/bin/dpkg", args: ["-i", debPath], root: true)
        if (ret != 0) {
            completion(local("DPKG_ERROR"), ret)
            return
        }
        
        if (!envInfo.isRootful) {
            ret = spawn(command: "\(envInfo.installPrefix)/usr/bin/apt-get", args: ["install", "-f", "-y", "--allow-unauthenticated"], root: true)
            if (ret != 0) {
                completion(local("DPKG_ERROR"), ret)
                return
            }
        }

        // uicache
        ret = spawn(command: "\(envInfo.installPrefix)/usr/bin/uicache", args: ["-a"], root: true)
        if (ret != 0) {
            completion(local("UICACHE_ERROR"), ret)
            return
        }
        
        // clean up
        defaultSources(for: URL(string: deb)!.lastPathComponent)
        cleanUp()
        completion(local("INSTALL_DONE"), 0)
        return
    }
}

