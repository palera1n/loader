//
//  Download.swift
//  loader-rewrite
//
//  Created by samara on 1/30/24.
//

import Foundation
import UIKit

// MARK: - Attempt to install

class Go: NSObject {
    
    static let shared = Go()
    var delegate: BootstrapLabelDelegate?
    
    var destinationUrl: URL?
    var downloadCompletion: ((String?, Error?) -> Void)?
    var startTime: Date?
    var bytesReceived: Int64 = 0
    
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
                        
                        delegate?.updateBootstrapLabel(withText: .localized("Installing Item", arguments: "\(file.capitalized)"))
                        delegate?.updateSpeedLabel(withText: .localized("Installing Explanation"))
                        DispatchQueue(label: "Install Strap").async {
                            if Preferences.doPasswordPrompt! {
                                DispatchQueue.main.async {
                                    self.displayPrompt { password in
                                        if let p = password {
                                            self.installBootstrap(tar: bootstrapFilePath, deb: pkgmgrFilePath, p: p)
                                        }
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

// MARK: - Download url

extension Go: URLSessionDownloadDelegate {
    
    func downloadFile(url: URL, completion: @escaping (String?, Error?) -> Void) {
        destinationUrl = URL(fileURLWithPath: "/tmp/palera1n/").appendingPathComponent(url.lastPathComponent)
        
        if url.lastPathComponent.contains("tar") || url.lastPathComponent.contains("zst") {
            delegate?.updateBootstrapLabel(withText: .localized("Downloading Base System"))
        } else {
            let fileNameWithoutExtension = (url.lastPathComponent as NSString).deletingPathExtension
            delegate?.updateBootstrapLabel(withText: .localized("Download Item", arguments: "\(fileNameWithoutExtension.capitalized)"))
        }
        
        downloadCompletion = completion
        startTime = Date()
        bytesReceived = 0
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        let downloadTask = session.downloadTask(with: url)
        downloadTask.resume()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let destinationUrl = destinationUrl else {
            return
        }
        
        let fileManager = FileManager.default
        do {
            if fileManager.fileExists(atPath: destinationUrl.path) {
                try fileManager.removeItem(at: destinationUrl)
            }
            
            try fileManager.moveItem(at: location, to: destinationUrl)
            downloadCompletion?(destinationUrl.path, nil)
            log(type: .info, msg: "Saved to: \(destinationUrl.path)")
        } catch {
            downloadCompletion?(destinationUrl.path, error)
            log(type: .fatal, msg: "Failed to save file at: \(destinationUrl.path), \(String(describing: error))")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let destinationUrl = destinationUrl else {
            return
        }
        
        if let error = error {
            downloadCompletion?(destinationUrl.path, error)
            log(type: .fatal, msg: "Failed to download: \(task.originalRequest?.url?.absoluteString ?? "Unknown URL"), \(error.localizedDescription)")
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let currentTime = Date()
        if startTime == nil {
            startTime = currentTime
        }
        
        let elapsedTime = currentTime.timeIntervalSince(startTime!)
        let speed = Double(totalBytesWritten) / elapsedTime
        
        let speedWithUnit = formattedSpeed(speed)
        
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        
        log(msg: "Download progress: \(progress * 100)%, \(speedWithUnit)")
        delegate?.updateDownloadProgress(progress: Double(progress))
        delegate?.updateSpeedLabel(withText: String.localized("Download Speed", arguments: speedWithUnit))
    }
    
    func formattedSpeed(_ speed: Double) -> String {
        let absSpeed = abs(speed)
        let units = ["B/s", "KB/s", "MB/s", "GB/s", "TB/s"]
        var index = 0
        var speedInBytes = absSpeed
        
        while speedInBytes >= 1024 && index < units.count - 1 {
            speedInBytes /= 1024
            index += 1
        }
        
        let formattedSpeed = String(format: "%.2f", speedInBytes)
        return "\(formattedSpeed) \(units[index])"
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
    static public func restoreSystem(isCleanFakeFS: Bool) -> Void {
        do {
            ObliterateJailbreak(isCleanFakeFS: isCleanFakeFS)
            ReloadLaunchdJailbreakEnvironment()
        }
        
        if paleInfo.palerain_option_ssv {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIApplication.prepareForExitAndSuspend()
        }
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
