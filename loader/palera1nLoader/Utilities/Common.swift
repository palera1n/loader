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
    static var isSimulator: Bool = false
    static var installPrefix: String = "unset"
    static var rebootAfter: Bool = true
    static var jsonURI: String {
        get { UserDefaults.standard.string(forKey: "JsonURI") ?? "https://palera.in/loader.json" }
        set { UserDefaults.standard.set(newValue, forKey: "JsonURI") }
    }
    static var envType: Int = -1
    static var systemVersion: String = "unset"
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
    static var tmpDir = create_temp_dir()
}

// String Localization
public func local(_ str: String.LocalizationValue) -> String {
    return String(localized: str)
}

public func fileExists(_ path: String) -> Bool {
    return fm.fileExists(atPath: path)
}

public func create_temp_dir() -> String? {
    let fm = FileManager.default
    let hash = container.generate_hash()
    var path = String()
    
    if (fileExists("/private/var/tmp")) {
        path = "/private/var/tmp/" + hash
    } else {
        path = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].path + "/\(hash)"
    }
    
    do {
        try fm.createDirectory(atPath: path, withIntermediateDirectories: false)
    } catch {
        log(type: .warning, msg: "failed to create \(path): \(error)")
        return nil
    }
    
    chmod(path, 0777)
    chown(path, 501, 501)
    return path
}

extension UIApplication {
    public func openSpringBoard() {
        opener.openApp("com.apple.springboard")
    }
}
