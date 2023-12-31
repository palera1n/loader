//
//  Bootstrapper.swift
//  palera1nLoader
//
//  Created by samara on 12/30/23.
//

/*
 // Fugu15
 MIT License
 
 Copyright (c) 2022 Pinauten GmbH
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 // Dopamine
 MIT License
 
 Copyright (c) 2023 Lars Fröder (opa334)
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 
 
 */

import Foundation
import CryptoKit

public class Bootstrapper {
    static func remountPrebootPartition(writable: Bool) -> Int? {
        if writable {
            return spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"])
        } else {
            return spawn(command: "/sbin/mount", args: ["-u", "/private/preboot"])
        }
    }
    
    static func zstdDecompress(zstdPath: String, targetTarPath: String) -> Int { return spawn(command: "/cores/binpack/usr/bin/zstd", args: ["-d", zstdPath, "-o", targetTarPath]) }
    
    static func untar(tarPath: String, target: String) -> Int? {
        let tarBinary = "/cores/binpack/usr/bin/tar"
        return spawn(command: tarBinary, args: ["-xpkf", tarPath, "-C", target])
    }
    
    static func generateFakeRootPath() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var result = ""
        for _ in 0..<8 {
            let randomIndex = Int(arc4random_uniform(UInt32(letters.count)))
            let randomCharacter = letters[letters.index(letters.startIndex, offsetBy: randomIndex)]
            result += String(randomCharacter)
        }
        return "/private/preboot/" + VersionSeeker.bootmanifestHash()! + "/jb-" + result
    }
    
    public static func locateExistingFakeRoot() -> String? {
        guard let bootManifestHash = VersionSeeker.bootmanifestHash() else {
            return nil
        }
        let ppURL = URL(fileURLWithPath: "/private/preboot/" + bootManifestHash)
        guard let candidateURLs = try? FileManager.default.contentsOfDirectory(at: ppURL , includingPropertiesForKeys: nil, options: []) else { return nil }
        for candidateURL in candidateURLs {
            if candidateURL.lastPathComponent.hasPrefix("jb-") {
                return candidateURL.path
            }
        }
        return nil
    }
    
    static func getTarHash(for tar: String) -> String {
        if #available(iOS 13.0, *) {
            if let data = tar.data(using: .utf8) {
                let hash = SHA256.hash(data: data)
                let hashString = hash.map { String(format: "%02hhx", $0) }.joined()
                return hashString
            }
        }
        return ""
    }
    
    static func fileOrSymlinkExists(atPath path: String) -> Bool {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            return true
        }
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            if let fileType = attributes[.type] as? FileAttributeType, fileType == .typeSymbolicLink {
                return true
            }
        } catch _ { }
        
        return false
    }
    
    static func extractBootstrap(tar: String) throws {
        let bootstrapTmpTarPath = "/tmp/palera1n/temp/bootstrap.tar"
        var fakeRootPath = locateExistingFakeRoot()
        if fakeRootPath == nil && paleInfo.palerain_option_rootless {
            fakeRootPath = generateFakeRootPath()
            spawn(command: "/cores/binpack/bin/mkdir", args: ["-p", fakeRootPath!])
        }
        let procursusPath = fakeRootPath! + "/procursus"
        var installedFilePath = ""
        
        // dotfile path
        if paleInfo.palerain_option_rootless {
            installedFilePath = procursusPath + "/.installed_palera1n"
        } else {
            installedFilePath = "/.installed_palera1n"
        }

        if paleInfo.palerain_option_rootless {
            let jbPath = "/var/jb"
            
            // Remount
            if remountPrebootPartition(writable: true) != 0 {
                log(type: .error, msg: "Failed to remount /private/preboot partition as writable")
            }
            binpack.rm(jbPath)
            
            // delete previous fakeroot if any
            binpack.rm(procursusPath)
                    
            // create /var/jb symlink
            binpack.mv(procursusPath, jbPath)
        }
        
        
        // tar
        let bootManifestHash = VersionSeeker.bootmanifestHash()
        let ppURL = "/private/preboot/" + bootManifestHash! + "/temp"
        spawn(command: "/cores/binpack/bin/mkdir", args: ["-p", ppURL])
        
        if FileManager.default.fileExists(atPath: bootstrapTmpTarPath) {
             binpack.rm(bootstrapTmpTarPath);
         }
         let zstdRet = zstdDecompress(zstdPath: tar, targetTarPath: bootstrapTmpTarPath)
         if zstdRet != 0 {
             log(type: .error, msg: String(format:"Failed to decompress bootstrap: \(String(describing: zstdRet))"))
         }
         // untar
         if paleInfo.palerain_option_rootless {
             let untarRet = untar(tarPath: bootstrapTmpTarPath, target: ppURL)
             if untarRet != 0 {
                 log(type: .error, msg: String(format:"Failed to untar bootstrap: \(String(describing: untarRet))"))
             }
         } else {
             let untarRet = untar(tarPath: bootstrapTmpTarPath, target: "/")
             if untarRet != 0 {
                 log(type: .error, msg: String(format:"Failed to untar bootstrap: \(String(describing: untarRet))"))
             }
         }
         
         binpack.rm(bootstrapTmpTarPath);
         if paleInfo.palerain_option_rootless {
             spawn(command: "/cores/binpack/bin/mv", args: ["-f", ppURL + "/var/jb", procursusPath])
         }
        
        //
    }
    
    static func needsFinalize() -> Bool {
        if paleInfo.palerain_option_rootless {
            return FileManager.default.fileExists(atPath: "/var/jb/prep_bootstrap.sh")
        } else {
            return FileManager.default.fileExists(atPath: "/prep_bootstrap.sh")
        }
    }
    
    static func finalizeBootstrap(deb: String) throws {
        var prefix = ""
        if paleInfo.palerain_option_rootless { prefix = "/var/jb" }
        let debPath = "/tmp/palera1n/\(deb)"
        
        // prep bootstrap
        let prepRet = spawn(command: "\(prefix)/bin/sh", args: ["\(prefix)/prep_bootstrap.sh"])
        if prepRet != 0 {
            log(type: .error, msg: String(format:"Failed to finalize bootstrap, prep_bootstrap.sh failed with error code: \(prepRet)"))
        }
        
        // install packages from json
        if (spawn(command: "\(prefix)/usr/bin/apt-get", args: ["update", "--allow-insecure-repositories"]) != 1) {
            if let assetsInfo = getAssetsInfo(envInfo.jsonInfo!) {
                let packages = assetsInfo.packages
                let repositories = assetsInfo.repositories
                
                print(packages)
                let repos = packages.joined(separator: "")
                
                for package in repositories {
                    let command = ["\(prefix)/usr/bin/apt-get", "-o", "Dpkg::Options::=--force-confnew", "install", package, "-y", "--allow-unauthenticated"]

                    var ret = spawn(command: command[0], args: Array(command[1...]))
                    if ret != 0 {
                        log(type: .error, msg: String(format: "Failed to execute command: %@, error code: %d", command.joined(separator: " "), ret))
                        return
                    }
                }
            }
        }
        
        // install debian
        let debRet = spawn(command: "\(prefix)/usr/bin/dpkg", args: ["-i", debPath])
        if debRet != 0 {
            log(type: .error, msg: String(format:"Failed to finalize bootstrap, installing libjbdrw failed with error code: \(debRet)"))
        }
    }
    
    static func uninstallBootstrap() {
        let jbPath = "/var/jb"
        
        if remountPrebootPartition(writable: true) != 0 {
            print("Failed to remount /private/preboot partition as writable")
            return
        }
        
        // Delete /var/jb symlink
        binpack.rm(jbPath)
        
        // Delete fake root
        let fakeRootPath = locateExistingFakeRoot()
        if fakeRootPath != nil {
            do {
                binpack.rm(fakeRootPath!)
            }
        }
        
        if remountPrebootPartition(writable: false) != 0 {
            print("Failed to remount /private/preboot partition as non-writable")
            return
        }
    }
}
