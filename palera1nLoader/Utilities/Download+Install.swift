//
//  Download.swift
//  loader-rewrite
//
//  Created by samara on 1/30/24.
//

import Foundation
import UIKit

// MARK: - Attempt to install

class Go {
    
    static let shared = Go()
    weak var delegate: BootstrapLabelDelegate?
    
    /// Install
    func attemptInstall(file: String) {
        
        guard let bootstrapUrl = JailbreakConfiguration.getBootstrapURL(jsonInfo!),
              let pkgmgrUrl = JailbreakConfiguration.getManagerURL(jsonInfo!, file) else {
            log(type: .fatal, msg: "Invalid URLs?")
            return
        }
                
        downloadFile(url: URL(string: bootstrapUrl)!) { [self] bootstrapFilePath, bootstrapError in
            if let bootstrapFilePath = bootstrapFilePath {
                downloadFile(url: URL(string: pkgmgrUrl)!) { [self] pkgmgrFilePath, pkgmgrError in
                    if let pkgmgrFilePath = pkgmgrFilePath {
                        DispatchQueue.main.async {
                            self.updateBootstrapLabel(file: file) {
                                if Preferences.doPasswordPrompt! {
                                    self.displayPrompt { password in
                                        if let password = password {
                                            self.installBootstrap(tar: bootstrapFilePath, deb: pkgmgrFilePath, p: password)
                                        }
                                    }
                                } else {
                                    self.installBootstrap(tar: bootstrapFilePath, deb: pkgmgrFilePath, p: "alpine")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func updateBootstrapLabel(file: String?, completion: @escaping () -> Void) {
        delegate?.updateBootstrapLabel(withText: .localized("Installing Item", arguments: file!))
        completion()
    }
}

// MARK: - Download url

extension Go {
    /// Download a file depending on url
    func downloadFile(url: URL, completion: @escaping (String?, Error?) -> Void) {
        let destinationUrl = URL(fileURLWithPath: "/tmp/palera1n/").appendingPathComponent(url.lastPathComponent)

        if url.lastPathComponent.contains("tar") || url.lastPathComponent.contains("zst") {
            delegate?.updateBootstrapLabel(withText: .localized("Downloading Base System"))
        } else {
            let fileNameWithoutExtension = (url.lastPathComponent as NSString).deletingPathExtension
            delegate?.updateBootstrapLabel(withText: .localized("Download Item", arguments: "\(fileNameWithoutExtension.capitalized)"))
        }
        
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(destinationUrl.path, error)
                    log(type: .fatal, msg: "Failed to download: \(request), \(String(describing: error))")
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                    completion(destinationUrl.path, error)
                    log(type: .fatal, msg: "Unknown error on download: \((response as? HTTPURLResponse)?.statusCode ?? -1) - \(request), \(String(describing: error))")
                    return
                }
                
                if let data = data {
                    do {
                        try FileManager.default.createDirectory(at: destinationUrl.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
                        try data.write(to: destinationUrl, options: .atomic)
                        completion(destinationUrl.path, nil)
                        log(type: .info, msg: "Saved to: \(destinationUrl.path)")
                    } catch {
                        completion(destinationUrl.path, error)
                        log(type: .fatal, msg: "Failed to save file at: \(destinationUrl.path), \(String(describing: error))")
                    }
                } else {
                    completion(destinationUrl.path, error)
                    log(type: .fatal, msg: "Failed to download: \(request), \(String(describing: error))")
                }
            }
        }
        
        task.resume()
    }
}


// MARK: - Password Prompt

extension Go {
    /// Display prompt for setting password, for sudo
    func displayPrompt(completion: @escaping (String?) -> Void) {
        let message = String.localized("Password Explanation")
        let alertController = UIAlertController(title: .localized("Set Password"), message: message, preferredStyle: .alert)
        alertController.addTextField() { (password) in
            password.placeholder = .localized("Password")
            password.isSecureTextEntry = true
            password.keyboardType = UIKeyboardType.asciiCapable
        }

        alertController.addTextField() { (repeatPassword) in
            repeatPassword.placeholder = .localized("Repeat Password")
            repeatPassword.isSecureTextEntry = true
            repeatPassword.keyboardType = UIKeyboardType.asciiCapable
        }

        let setPassword = UIAlertAction(title: String.localized("Set"), style: .default) { _ in
            let password = alertController.textFields?[0].text
            completion(password)
        }
        setPassword.isEnabled = false
        alertController.addAction(setPassword)

        NotificationCenter.default.addObserver(
            forName: UITextField.textDidChangeNotification,
            object: nil,
            queue: .main
        ) { notification in
            let passOne = alertController.textFields?[0].text
            let passTwo = alertController.textFields?[1].text
            if (passOne!.count > 253 || passOne!.count > 253) {
                setPassword.setValue(String.localized("Too Long"), forKeyPath: "title")
            } else {
                setPassword.setValue(String.localized("Set"), forKeyPath: "title")
                setPassword.isEnabled = (passOne == passTwo) && !passOne!.isEmpty && !passTwo!.isEmpty
            }
        }
        
        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
            rootViewController.present(alertController, animated: true)
        }
    }
}


// MARK: - Remove envioronment
extension Go {
    
    /// Remove environment
    static public func restoreSystem() -> Void {
        if paleInfo.palerain_option_rootless {
            #warning("Someone need to add checks incase this fails")
            do {
                ObliterateJailbreak()
                ReloadLaunchdJailbreakEnvironment()
            }
            
            if Preferences.rebootOnRevert! {
                spawn(command: "/cores/binpack/bin/launchctl", args: ["reboot"])
            } else {
                if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                    let alert = UIAlertController.error(title: .localized("Done"), message: "", actions: [])
                    rootViewController.present(alert, animated: true)
                }
            }
        }
    }
    
}

// MARK: - Install enviornment
extension Go {
    /// Install environment
    private func installBootstrap(tar: String, deb: String, p: String) {
        print("Tar: \(tar) \nDeb: \(deb) \nPassword: \(p) ")
        print("do the thing!")
        #if !targetEnvironment(simulator)
        if paleInfo.palerain_option_rootless { spawn(command: "/cores/binpack/bin/rm", args: ["-rf", "/var/jb"]) }
        #endif
        
        let (deployBootstrap_ret, resultDescription) = DeployBootstrap(path: tar, deb: deb, password: p);
        if (deployBootstrap_ret != 0) {
            log(type: .fatal, msg: "Bootstrapper error occurred: \(resultDescription)")
            return
        }
        
        ReloadLaunchdJailbreakEnvironment()
        
        Go.cleanUp()
        UIApplication.prepareForExitAndSuspend()
    }
}


// MARK: - Clean up temporary directory
extension Go {
    
    /// Clean up downloads + tmp directory
    static public func cleanUp() -> Void {
        let tmp = "/tmp/palera1n"
        
        URLCache.shared.removeAllCachedResponses()
        
        do {
            let tmpFile = try FileManager.default.contentsOfDirectory(at: URL(string: tmp)!, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for url in tmpFile {try FileManager.default.removeItem(at: url)}}
        catch {
            return
        }
    }

}
