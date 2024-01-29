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
            spawn(command: "\(prefix)/usr/bin/apt-get", args: ["--fix-broken", "--allow-downgrades", "-y", "--allow-unauthenticated", "dist-upgrade"])
            if let assetsInfo = getAssetsInfo(envInfo.jsonInfo!) {
                let packages = assetsInfo.packages
                let repositories = assetsInfo.repositories
                
                for package in repositories {
                    let command = ["\(prefix)/usr/bin/apt-get", "-o", "Dpkg::Options::=--force-confnew", "install", package, "-y", "--allow-unauthenticated"]

                    let ret = spawn(command: command[0], args: Array(command[1...]))
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
}
