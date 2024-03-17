//
//  OpenApplication.swift
//  palera1nLoader
//
//  Created by samara on 3/16/24.
//

import Foundation
import Bridge

class opener {
    @discardableResult
    static public func openApp(_ bundle: String) -> Bool {
        return LSApplicationWorkspace.default().openApplication(withBundleID: bundle)
    }
}
