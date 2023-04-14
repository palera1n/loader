//
//  Common.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/10/23.
//

import Foundation
import LaunchServicesBridge
import UIKit

var observation: NSKeyValueObservation?
let progressDownload : UIProgressView = UIProgressView(progressViewStyle: .default)
let global = (UIApplication.shared.connectedScenes.filter { $0.activationState == .foregroundActive }
    .first(where: { $0 is UIWindowScene }).flatMap({ $0 as? UIWindowScene })?.windows.first(where: \.isKeyWindow)?.rootViewController!)!


func local(_ str: String.LocalizationValue) -> String {
    return String(localized: str)
}

func errAlert(title: String, message: String) {
    DispatchQueue.main.async {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: local("CLOSE"), style: .default) { _ in
            cleanUp()
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { exit(0) }
        })
        if (global.presentedViewController != nil) {
            global.presentedViewController?.dismiss(animated: true)
        }
        global.present(alertController, animated: true, completion: nil)
    }
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


func spinnerAlert(_ str: String.LocalizationValue, start: Bool) {
    DispatchQueue.main.async {
        let loadingAlert = UIAlertController(title: nil, message: local(str), preferredStyle: .alert)
        if (start) {
            if (global.presentedViewController != nil) {global.presentedViewController?.dismiss(animated: true)}
            if (str != "INSTALLING" && str != "REMOVING") {
                let constraintHeight = NSLayoutConstraint(
                      item: loadingAlert.view!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute:
                      NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 75)
                loadingAlert.view.addConstraint(constraintHeight)
                progressDownload.setProgress(0.0/1.0, animated: true)
                progressDownload.frame = CGRect(x: 25, y: 55, width: 220, height: 0)
                loadingAlert.view.addSubview(progressDownload)
            } else {
                let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
                loadingAlert.view.addSubview(loadingIndicator)
                loadingIndicator.hidesWhenStopped = true
                loadingIndicator.startAnimating()
            }
            global.present(loadingAlert, animated: true, completion: nil)
        } else {
            if (global.presentedViewController != nil) {global.presentedViewController?.dismiss(animated: true)}
            loadingAlert.dismiss(animated: true)
        }
    }
}


func download(_ file: String,_ rootful: Bool) -> Void {
    deleteFile(file: file)
    switch (file) {
        case "bootstrap.tar": spinnerAlert("DL_STRAP", start: true)
        case "sileo.deb": spinnerAlert("DL_SILEO", start: true)
        case "zebra.deb": spinnerAlert("DL_ZEBRA", start: true)
        default: spinnerAlert("DOWNLOADING", start: true)
    }
    
    let server = rootful == true ? "https://static.palera.in" : "https://static.palera.in/rootless"
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let fileURL = documentsURL.appendingPathComponent(file)
    let url = URL(string: "\(server)/\(file)")!
    let semaphore = DispatchSemaphore(value: 0)
    let config = URLSessionConfiguration.default
    let session = URLSession(configuration: config)
    let task = session.downloadTask(with: url) { tempLocalUrl, response, error in
        if let statusCode = (response as? HTTPURLResponse)?.statusCode {
            if statusCode != 200 {
                if server.contains("cdn.nickchan.lol") {
                    spinnerAlert("DOWNLOADING", start: false)
                    errAlert(title: local("DOWNLOAD_FAIL"), message: "\(error?.localizedDescription ?? local("DOWNLOAD_ERROR"))")
                    NSLog("[palera1n] Could not download file: \(error?.localizedDescription ?? "Unknown error")");return
                };return
            }
        }
        if let tempLocalUrl = tempLocalUrl, error == nil {
            do {
                try FileManager.default.copyItem(at: tempLocalUrl, to: fileURL)
                semaphore.signal()
                spinnerAlert("DOWNLOADING", start: false)
            } catch (let writeError) {
                spinnerAlert("DOWNLOADING", start: false)
                errAlert(title: local("SAVE_FAIL"), message: "\(writeError)")
                NSLog("[palera1n] Could not copy file to disk: \(error?.localizedDescription ?? "Unknown error")");return
            }
        } else {
            spinnerAlert("DOWNLOADING", start: false)
            errAlert(title: local("DOWNLOAD_FAIL"), message: "\(error?.localizedDescription ?? local("DOWNLOAD_ERROR"))")
            NSLog("[palera1n] Could not download file: \(error?.localizedDescription ?? "Unknown error")");return
        }
    }
    observation = task.progress.observe(\.fractionCompleted) { progress, _ in
        print("progress: ", progress.fractionCompleted)
        DispatchQueue.main.async {
            progressDownload.setProgress(Float(progress.fractionCompleted/1.0), animated: true)
        }
    }
    task.resume()
    semaphore.wait()
}

func deviceCheck() -> Void {
#if targetEnvironment(simulator)
    print("[palera1n] Running in simulator")
#else
    guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
        errAlert(title: "Could not find helper?", message: "If you've sideloaded this loader app unfortunately you aren't able to use this, please jailbreak with palera1n before proceeding.")
        return
    }
    
    let ret = spawn(command: helper, args: ["-f"], root: true)
    rootful = ret == 0 ? false : true
    inst_prefix = rootful ? "/" : "/var/jb"
    let retRFR = spawn(command: helper, args: ["-n"], root: true)
    let rfr = retRFR == 0 ? false : true

    if rfr {
        errAlert(title: "Unable to continue", message: "Bootstrapping after using --force-revert is not supported, please rejailbreak to be able to bootstrap again.")
        return
    }
#endif
}
