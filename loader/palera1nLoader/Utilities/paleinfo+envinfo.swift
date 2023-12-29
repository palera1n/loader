//
//  paleinfo.swift
//  palera1nLoader
//
//  Created by samara on 12/21/23.
//

import Foundation
import UIKit

let paleInfo = paleinfo()

struct paleinfo {
    var palerain_option_rootful: Bool
    var palerain_option_rootless: Bool
    var palerain_option_force_revert: Bool
    var palerain_option_safemode: Bool
    var palera1n_option_flower_chain: Bool
    
    init() {
        let hex = envInfo.pinfoFlags
        let new = hex.replacingOccurrences(of: "[^0-9a-fA-F]", with: "", options: .regularExpression)
        
        guard let flags = UInt64(new, radix: 16) else {
            self.palerain_option_rootful = false
            self.palerain_option_rootless = false
            self.palerain_option_force_revert = false
            self.palerain_option_safemode = false
            self.palera1n_option_flower_chain = false
            return
        }

        self.palerain_option_rootful = (flags & (1 << 0)) != 0
        self.palerain_option_rootless = (flags & (1 << 1)) != 0
        self.palerain_option_force_revert = (flags & (1 << 24)) != 0
        self.palerain_option_safemode = (flags & (1 << 25)) != 0
        self.palera1n_option_flower_chain = (flags & (1 << 61)) != 0
    }
}

struct envInfo {
    static var pinfoFlags: String = ""
    static var installPrefix: String = ""
    
    static var rebootAfter: Bool = true
    static var w_button: Bool = false
    
    static var jsonInfo: loaderJSON?
    static var jsonURI: String {
        get { UserDefaults.standard.string(forKey: "JsonURI") ?? "https://palera.in/loader.json" }
        set { UserDefaults.standard.set(newValue, forKey: "JsonURI") }
    }
    static var nav: UINavigationController = UINavigationController()
}
