//
//  paleinfo.swift
//  loader-rewrite
//
//  Created by samara on 1/29/24.
//

import Foundation

let paleInfo = paleinfo()

struct paleinfo {
    /// User specified `-l` (rootless)
    var palerain_option_rootful: Bool
    /// User specified `-f` (rootful)
    var palerain_option_rootless: Bool
    /// System has signed system volum
    var palerain_option_ssv: Bool
    /// User specified `--force-revert` (remove jailbreak)
    var palerain_option_force_revert: Bool
    /// User specified `-s` (safemode)
    var palerain_option_safemode: Bool
    /// If user has happened to have an rsod
    var palerain_option_failure: Bool
    /// 
    var palerain_option_flower_chain: Bool
        
    init() {
        let flags = GetPinfoFlags();
        self.palerain_option_rootful = (flags & (1 << 0)) != 0
        self.palerain_option_rootless = (flags & (1 << 1)) != 0
        self.palerain_option_ssv = (flags & (1 << 7)) != 0
        self.palerain_option_force_revert = (flags & (1 << 24)) != 0
        self.palerain_option_safemode = (flags & (1 << 25)) != 0
        self.palerain_option_failure = (flags & (1 << 60)) != 0
        self.palerain_option_flower_chain = (flags & (1 << 61)) != 0
    }
}
