//
//  Common.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/10/23.
//

import Foundation
import LaunchServicesBridge

func deviceCheck() -> Void {
#if targetEnvironment(simulator)
    print("[palera1n] Running in simulator")
#else
    guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
        let alertController = ViewController().errorAlert(title: "Could not find helper?", message: "If you've sideloaded this loader app unfortunately you aren't able to use this, please jailbreak with palera1n before proceeding.")
        print("[palera1n] Could not find helper?")
        ViewController().present(alertController, animated: true, completion: nil)
        return
    }
    
    let ret = spawn(command: helper, args: ["-f"], root: true)
    ViewController().rootful = ret == 0 ? false : true
    ViewController().inst_prefix = ViewController().rootful ? "" : "/var/jb"
    
    let retRFR = spawn(command: helper, args: ["-n"], root: true)
    let rfr = retRFR == 0 ? false : true
    if rfr {
        let alertController = ViewController().errorAlert(title: "Unable to continue", message: "Bootstrapping after using --force-revert is not supported, please rejailbreak to be able to bootstrap again.")
        ViewController().present(alertController, animated: true, completion: nil)
        return
    }
#endif
}

func openApp(_ bundle: String) -> Bool {
    return LSApplicationWorkspace.default().openApplication(withBundleID: bundle)
}
