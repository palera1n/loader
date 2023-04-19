//
//  Common.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/10/23.
//

import Foundation
import LaunchServicesBridge
import UIKit

let global = (UIApplication.shared.connectedScenes.filter { $0.activationState == .foregroundActive }
    .first(where: { $0 is UIWindowScene }).flatMap({ $0 as? UIWindowScene })?.windows.first(where: \.isKeyWindow)?.rootViewController!)!

func local(_ str: String.LocalizationValue) -> String {
    return String(localized: str)
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

func warningAlert(title: String, message: String, destructiveButtonTitle: String?, destructiveHandler: (() -> Void)?) {
    DispatchQueue.main.async {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if let destructiveTitle = destructiveButtonTitle, let handler = destructiveHandler {
            alertController.addAction(UIAlertAction(title: destructiveTitle, style: .destructive) { _ in
                handler()
            })
        }
        
        alertController.addAction(UIAlertAction(title: local("CANCEL"), style: .cancel) { _ in
            return
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
