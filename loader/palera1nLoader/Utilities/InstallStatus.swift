//
//  Checks.swift
//  palera1nLoader
//
//  Created by Staturnz on 6/11/23.
//

import Foundation
import UIKit
import MachO
import Darwin.POSIX

enum installStatus {
    case simulated
    case rootful
    case rootful_installed
    case rootless
    case rootless_installed
}

class Check {
    static public func installation() -> installStatus {
        #if targetEnvironment(simulator)
        return .simulated
        #else
        if paleInfo.palerain_option_rootful {
            if FileManager.default.fileExists(atPath: "/.procursus_strapped") {
                return .rootful_installed
            } else {
                return .rootful
            }
        }

        if paleInfo.palerain_option_rootless {
            if FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                return .rootless_installed
            } else {
                return .rootless
            }
        }
        return .rootless
        #endif
    }
    
    @discardableResult
    static public func loaderDirectories() -> Bool {
        if (!fileExists("/tmp/palera1n")) {
            
            let dirs = ["/tmp/palera1n/logs", "/tmp/palera1n/temp"]
            
            do {
                for path in dirs { try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true) }
            } catch {
                log(type: .error, msg: "Failed to create temp directories: \(error)")
                return false
            }
        }
        
        return true
    }
    
    static public func prerequisites() -> Void {
        helper(args: ["palera1n_flags"])
        
        envInfo.installPrefix = paleInfo.palerain_option_rootful ? "" : "/var/jb"
        
        log(msg: "Jailbreak Type: \(paleInfo.palerain_option_rootful ? "Rootful" : "Rootless")")
        log(msg: "pinfo: \(envInfo.pinfoFlags)")
        log(msg: "CoreFoundation: \(VersionSeeker.corefoundationVersionShort)")
    }
}
