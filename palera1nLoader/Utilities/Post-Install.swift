//
//  Post.swift
//  loader-rewrite
//
//  Created by samara on 2/4/24.
//

import Foundation
import UIKit

class Finalize {
    weak var delegate: BootstrapLabelDelegate?
    func finalizeBootstrap(deb: String) throws {
        var prefix = ""
        if paleInfo.palerain_option_rootless { prefix = "/var/jb" }
        
        // install packages from json
        if (spawn(command: "\(prefix)/usr/bin/apt-get", args: ["update", "--allow-insecure-repositories"]) != 1) {
            spawn(command: "\(prefix)/usr/bin/apt-get", args: ["--fix-broken", "--allow-downgrades", "-y", "--allow-unauthenticated", "dist-upgrade"])
            if let assetsInfo = JailbreakConfiguration.getAssetsInfo(jsonInfo!) {
                let repositories = assetsInfo.repositories
                
                for package in repositories {
                    let command = ["\(prefix)/usr/bin/apt-get", "-o", "Dpkg::Options::=--force-confnew", "install", package, "-y", "--allow-unauthenticated"]
                    
                    let ret = spawn(command: command[0], args: Array(command[1...]))
                    if ret != 0 {
                        log(type: .error, msg: "Failed to run: \(ret)")
                        return
                    }
                }
            }
        }
        
        // install debian
        let debRet = spawn(command: "\(prefix)/usr/bin/dpkg", args: ["-i", deb])
        if debRet != 0 {
            log(type: .fatal, msg: "Failed to finalize bootstrap, error code: \(debRet)")
        }
        _ = spawn(command: "/cores/binpack/usr/bin/uicache", args: ["-a"])
        
        self.setRepositories()
    }
    
    func setRepositories() {
        guard let assetsInfo = JailbreakConfiguration.getAssetsInfo(jsonInfo!) else {
            return
        }

        let repositoriesContent = assetsInfo.packages.joined(separator: "\n")

        let sourcePath = paleInfo.palerain_option_rootless
        ? "/var/jb/etc/apt/sources.list.d/palera1n.sources"
        : "/etc/apt/sources.list.d/palera1n.sources"

        let (deployBootstrap_ret, resultDescription) = OverwriteFile(destination: sourcePath, content: repositoriesContent)

        if deployBootstrap_ret != 0 {
            log(type: .fatal, msg: "Bootstrapper error occurred: \(resultDescription)")
        }
    }
    
    func postManagerInstall(deb: String) {
        var prefix = ""
        if paleInfo.palerain_option_rootless { prefix = "/var/jb" }
        self.delegate?.updateBootstrapLabel(withText: .localized("Installing Item", arguments: ")"))

        #if !targetEnvironment(simulator)
        let debRet = spawn(command: "\(prefix)/usr/bin/dpkg", args: ["-i", deb])
        if debRet != 0 {
            log(type: .fatal, msg: "Failed to finalize bootstrap, error code: \(debRet)")
        }
        
        _ = spawn(command: "/cores/binpack/usr/bin/uicache", args: ["-a"])
        #endif
        Go.cleanUp()
        UIApplication.prepareForExitAndSuspend()
    }
}

extension Go {
    func attemptManagerInstall(file: String) {
        guard let pkgmgrUrl = JailbreakConfiguration.getManagerURL(jsonInfo!, file) else {
            log(type: .fatal, msg: "Invalid URLs?")
            return
        }
        
        downloadFile(url: URL(string: pkgmgrUrl)!) { pkgmgrFilePath, pkgmgrError in
            if let pkgmgrFilePath = pkgmgrFilePath {
                self.updateBootstrapLabel(file: file) {
                    Finalize().postManagerInstall(deb: pkgmgrFilePath)
                }
            }
        }
    }
}
