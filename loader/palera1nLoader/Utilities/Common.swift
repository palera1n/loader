//
//  Common.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/10/23.
//

import Foundation
import Extras
import UIKit

let isIpad = UIDevice.current.userInterfaceIdiom

class LocalizationManager {
    static let shared = LocalizationManager()
    
    private var localizedStrings: [String: String] = [:]
    
    private init() {
        if let path = Bundle.main.path(forResource: "Localizable", ofType: "strings"),
           let dictionary = NSDictionary(contentsOfFile: path) as? [String: String] {
            localizedStrings = dictionary
        }
    }
    
    func local(_ key: String) -> String {
        return localizedStrings[key] ?? key
    }
}

public func fileExists(_ path: String) -> Bool {
    return FileManager.default.fileExists(atPath: path)
}

extension UIApplication {
    public func openSpringBoard() {
        let workspace = LSApplicationWorkspace.default()!
        workspace.openApplication(withBundleID: "com.apple.springboard")
    }
}

class opener {
    @discardableResult
    static public func openApp(_ bundle: String) -> Bool {
        return LSApplicationWorkspace.default().openApplication(withBundleID: bundle)
    }
}
