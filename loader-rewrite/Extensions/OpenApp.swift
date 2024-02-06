//
//  Open.swift
//  loader-rewrite
//
//  Created by samara on 1/30/24.
//

import Foundation
import UIKit
import Bridge

extension UIApplication {
    static func prepareForExitAndSuspend() {
        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
        exit(0)
    }
}
