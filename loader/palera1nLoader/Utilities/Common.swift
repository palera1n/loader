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
let fm = FileManager.default

struct envInfo {
    static var isRootful: Bool = false
    static var installPrefix: String = "unset"
    static var rebootAfter: Bool = true
    static var jsonURI: String {
        get { UserDefaults.standard.string(forKey: "JsonURI") ?? "https://palera.in/loader.json" }
        set { UserDefaults.standard.set(newValue, forKey: "JsonURI") }
    }
    static var envType: Int = -1
    static var systemArch: String = "unset"
    static var isInstalled: Bool = false
    static var hasForceReverted: Bool = false
    static var hasChecked: Bool = false
    static var kinfoFlags: String = ""
    static var pinfoFlags: String = ""
    static var kinfoFlagsStr: String = ""
    static var pinfoFlagsStr: String = ""
    static var jbFolder: String = ""
    static var CF = Int(floor(kCFCoreFoundationVersionNumber / 100) * 100)
    static var bmHash: String = ""
    static var nav: UINavigationController = UINavigationController()
    static var jsonInfo: loaderJSON?
}

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
    return fm.fileExists(atPath: path)
}

extension UIApplication {
  public func openSpringBoard() {
    let workspace = LSApplicationWorkspace.default() as! LSApplicationWorkspace
  workspace.openApplication(withBundleID: "com.apple.springboard")
  }
}
