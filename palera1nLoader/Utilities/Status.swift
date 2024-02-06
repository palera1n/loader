//
//  Install.swift
//  loader-rewrite
//
//  Created by samara on 1/30/24.
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

class Status {
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
}
