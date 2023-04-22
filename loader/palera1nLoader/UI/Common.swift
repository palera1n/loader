//
//  Common.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/10/23.
//

import Foundation
import LaunchServicesBridge
import UIKit

struct envInfo {
    static var isRootful: Bool = false
    static var isSimulator: Bool = false
    static var installPrefix: String = "unset"
    static var rebootAfter: Bool = true
    static var hasHelper: Bool = false
    static var helperPath: String = "unset"
    static var envType: Int = -1
    static var systemVersion: String = "unset"
    static var systemArch: String = "unset"
    static var isInstalled: Bool = false
    static var hasForceReverted: Bool = false
    static var sileoInstalled: Bool = false
    static var zebraInstalled: Bool = false
    static var hasChecked: Bool = false
}

// will be removed
let global = (UIApplication.shared.connectedScenes.filter { $0.activationState == .foregroundActive }
    .first(where: { $0 is UIWindowScene }).flatMap({ $0 as? UIWindowScene })?.windows.first(where: \.isKeyWindow)?.rootViewController!)!

func local(_ str: String.LocalizationValue) -> String {
    return String(localized: str)
}

func helperCmd(_ args: [String]) -> Int {
    return spawn(command: envInfo.helperPath, args: args, root: true)
}

func fileExists(_ path: String) -> Bool {
    return FileManager.default.fileExists(atPath: path)
}

func docsFile(file: String) -> String {
   return "\(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(file).path)"
}

func whichAlert(title: String, message: String? = nil) -> UIAlertController {
    if UIDevice.current.userInterfaceIdiom == .pad {
        return UIAlertController(title: title, message: message, preferredStyle: .alert)
    }
    return UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
}

func openApp(_ bundle: String) -> Bool {
    return LSApplicationWorkspace.default().openApplication(withBundleID: bundle)
}

func deleteFile(file: String) -> Void {
   let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
   let fileURL = documentsURL.appendingPathComponent(file)
   try? FileManager.default.removeItem(at: fileURL)
}

// will be removed
func errAlert(title: String, message: String) {
    DispatchQueue.main.async {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: local("CLOSE"), style: .default) { _ in
            bootstrap().cleanUp()
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { exit(0) }
        })
        
        if (global.presentedViewController != nil) {
            global.presentedViewController!.dismiss(animated: true) {
                global.present(alertController, animated: true, completion: nil)
            }
        } else {
            global.present(alertController, animated: true, completion: nil)
        }
    }
}
