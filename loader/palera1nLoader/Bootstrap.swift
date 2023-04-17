//
//  Bootstrap.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/12/23.
//

import Foundation
import UIKit

class bootstrap {
    var observation: NSKeyValueObservation?
    var progressDownload: UIProgressView = UIProgressView(progressViewStyle: .default)
    
    // Ran after bootstrap/deb install
    func cleanUp() -> Void {
        deleteFile(file: "sileo.deb")
        deleteFile(file: "zebra.deb")
        deleteFile(file: "bootstrap.tar")
        //deleteFile(file: "sources")
        
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
        
        do {
            let tmp = URL(string: NSTemporaryDirectory())!
            let tmpFile = try FileManager.default.contentsOfDirectory(at: tmp, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for url in tmpFile {try FileManager.default.removeItem(at: url)}}
        catch {
            NSLog("[palera1n] Error removing temp files: \(error)")
            return
        }
    }
    
    
    // Appends new defaults sources for Sileo and Zebra
    func defaultSources(_ pm: String,_ rootful: Bool) -> Void {
        let inst_prefix = rootful ? "" : "/var/jb"
        let zebraSources = "/var/mobile/Library/Application Support/xyz.willy.Zebra/sources.list"
        let sileoSources = "\(inst_prefix)/etc/apt/sources.list.d/procursus.sources"
        let sileoLine = "Types: deb\nURIs: https://repo.getsileo.app/\nSuites: ./\nComponents:\n"
        let CF = Int(floor(kCFCoreFoundationVersionNumber / 100) * 100)
        
        var (readPath,dataToWrite) = ("","")
        var (ellekitRepo,palera1nRepo,palera1nStrap,procursusStap,sileoRepo,zebraRepo) = (false,false,false,false,false,false)
        var (ellekitLine,procursusLine,palera1nLine,palestrapLine) = ("","","","")

        if (pm == "sileo") {
            readPath = sileoSources
            ellekitLine = "Types: deb\nURIs: https://ellekit.space/\nSuites: ./\nComponents:\n"
            palera1nLine = "Types: deb\nURIs: https://repo.palera.in/\nSuites: ./\nComponents:\n"
            procursusLine = "Types: deb\nURIs: https://apt.procurs.us/\nSuites: \(CF)\nComponents: main\n"
            palestrapLine = "Types: deb\n URIs: https://strap.palera.in/\nSuites: iphoneos-arm64/\(CF)\nComponents: main\n"
        } else {
            readPath = zebraSources
            ellekitLine = "deb https://ellekit.space/ ./\n"
            palera1nLine = "deb https://repo.palera.in/ ./\n"
            procursusLine = "deb https://apt.procurs.us/ \(CF) main\n"
            palestrapLine = "deb https://strap.palera.in/ iphoneos-arm64/\(CF) main\n"
        }
        
        guard let fd = fopen(readPath, "r") else { return }
        defer { fclose(fd) }

        while let line = readLine() {
            if (pm == "sileo") {
                if (line.hasPrefix("URIs: https://apt.procurs.us")) {procursusStap = true}
                if (line.hasPrefix("URIs: https://repo.palera.in/")) {palera1nRepo = true}
                if (line.hasPrefix("URIs: https://ellekit.space/")) {ellekitRepo = true}
                if (line.hasPrefix("URIs: https://strap.palera.in/")) {palera1nStrap = true}
                if (line.hasPrefix("URIs: https://repo.getsileo.app/")) {sileoRepo = true}
            } else {
                if (line.hasPrefix("deb https://apt.procurs.us")) {procursusStap = true}
                if (line.hasPrefix("deb https://repo.palera.in/")) {palera1nRepo = true}
                if (line.hasPrefix("deb https://ellekit.space/")) {ellekitRepo = true}
                if (line.hasPrefix("deb https://strap.palera.in/")) {palera1nStrap = true}
                if (line.hasPrefix("deb https://getzbra.com/repo/")) {zebraRepo = true}
            }
        }
        dataToWrite = try! String(contentsOfFile: readPath)
        dataToWrite = dataToWrite.replacingOccurrences(of: "\n\n", with: "\n") // format fix

        if (rootful) {
            if (!palera1nStrap) {dataToWrite = "\(dataToWrite)\n\(palestrapLine)"}
            if (!palera1nRepo) {dataToWrite = "\(dataToWrite)\n\(palera1nLine)"}
        } else {
            if (!procursusStap) {dataToWrite = "\(dataToWrite)\n\(procursusLine)"}
            if (!palera1nRepo) {dataToWrite = "\(dataToWrite)\n\(palera1nLine)"}
            if (!ellekitRepo) {dataToWrite = "\(dataToWrite)\n\(ellekitLine)"}
        }
        
        if (pm == "sileo") {if (!sileoRepo) {dataToWrite = "\(dataToWrite)\n\(sileoLine)"}}
        else {if (!zebraRepo) {dataToWrite = "\(dataToWrite)\n\(zebraRepo)"}}
        let docUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let tempFile = docUrl.appendingPathComponent("sources")
        try? dataToWrite.write(to: tempFile, atomically: true, encoding: String.Encoding.utf8)
        _ = spawn(command: "\(inst_prefix)/usr/bin/mv", args: [tempFile.path, readPath], root: true)
    }
    
    
    // File downloader for debs and strap
    func download(_ file: String,_ rootful: Bool) -> Void {
        deleteFile(file: file)
        let CF = Int(floor(kCFCoreFoundationVersionNumber / 100) * 100)
        let server = rootful == true ? "https://static.palera.in" : "https://static.palera.in/rootless"
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(file)
        var url = URL(string: "\(server)/\(file)")!
        if (file == "bootstrap.tar" && !rootful) {url = URL(string: "\(server)/bootstrap-\(CF).tar")!}
        
        let semaphore = DispatchSemaphore(value: 0)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        
        let task = session.downloadTask(with: url) { tempLocalUrl, response, error in
            if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if statusCode != 200 {
                    if server.contains("cdn.nickchan.lol") {
                        Utils().showToast(true, local("DOWNLOAD_FAIL"))
                        return
                    }
                    return
                }
            }
            if let tempLocalUrl = tempLocalUrl, error == nil {
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: fileURL)
                    semaphore.signal()
                } catch {
                    Utils().showToast(true, local("SAVE_FAIL"))
                    return
                }
            } else {
                Utils().showToast(true, local("DOWNLOAD_FAIL"))
                return
            }
        }
        
        self.observation = task.progress.observe(\.fractionCompleted) { progress, _ in
            print("progress: ", progress.fractionCompleted)
            DispatchQueue.main.async {
                if (file == "bootstrap.tar") {
                    self.progressDownload.setProgress(Float(progress.fractionCompleted/1.0), animated: true)
                }
            }
        }
        
        task.resume()
        semaphore.wait()
    }

    
    // Installs a given deb file
    func installDeb(_ file: String,_ rootful: Bool) -> Void {
        DispatchQueue.main.async {
            let loadingAlert = UIAlertController(title: nil, message: local("INSTALLING"), preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingAlert.view.addSubview(loadingIndicator)
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.startAnimating()
            global.present(loadingAlert, animated: true, completion: nil)
        }
        
        let downloadGroup = DispatchGroup()
        downloadGroup.enter()
        DispatchQueue.global(qos: .default).async {
            self.download("\(file).deb", rootful)
            downloadGroup.leave()
        }
        downloadGroup.wait()
        
        let inst_prefix = rootful ? "" : "/var/jb"
        let deb = "\(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(file).deb").path)" // gross
        
        var ret = spawn(command: "\(inst_prefix)/usr/bin/dpkg", args: ["-i", deb], root: true)
        if (ret != 0) {
            Utils().showToast(true, local("DPKG_ERROR"))
            return
        }
        
        ret = spawn(command: "\(inst_prefix)/usr/bin/uicache", args: ["-a"], root: true)
        if (ret != 0) {
            Utils().showToast(true, local("UICACHE_ERROR"))
            return
        }
        
        defaultSources(file, rootful)
        Utils().showToast(false, local("INSTALL_DONE"))
    }
    
    
    // Main bootstrap install
    func installStrap(_ pm: String,_ rootful: Bool) -> Void {
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
            print("[palera1n] Could not find helper?")
            return
        }
        
        if (!rootful && FileManager.default.fileExists(atPath: "/var/jb")) {
            let ret = spawn(command: helper, args: ["-r"], root: true)
            if (ret != 0) {
                Utils().showToast(true, local("STRAP_ERROR"))
                return
            }
        }
        
        let inst_prefix = rootful ? "/" : "/var/jb"
        let tar = docsFile(file: "bootstrap.tar")
        let deb = docsFile(file: "\(pm).deb")

        let downloadGroup = DispatchGroup()
        downloadGroup.enter()
        DispatchQueue.global(qos: .default).async {
            DispatchQueue.main.async {
                let loadingAlert = UIAlertController(title: nil, message: local("DOWNLOADING"), preferredStyle: .alert)
                let constraintHeight = NSLayoutConstraint(item: loadingAlert.view!, attribute: NSLayoutConstraint.Attribute.height,
                                                          relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute:
                                                            NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 75)
                loadingAlert.view.addConstraint(constraintHeight)
                self.progressDownload.setProgress(0.0/1.0, animated: true)
                self.progressDownload.frame = CGRect(x: 25, y: 55, width: 220, height: 0)
                loadingAlert.view.addSubview(self.progressDownload)
                global.present(loadingAlert, animated: true, completion: nil)
            }

            self.download("bootstrap.tar", rootful)
            self.download("\(pm).deb", rootful)
            downloadGroup.leave()
        }
        downloadGroup.wait()
        
        DispatchQueue.main.async {
            global.presentedViewController!.dismiss(animated: true) {
                let loadingAlert = UIAlertController(title: nil, message: local("INSTALLING"), preferredStyle: .alert)
                let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
                loadingAlert.view.addSubview(loadingIndicator)
                loadingIndicator.hidesWhenStopped = true
                loadingIndicator.startAnimating()
                global.present(loadingAlert, animated: true, completion: nil)
            }
        }
        
        spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
        if rootful { spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)}
        
        var ret = spawn(command: helper, args: ["-i", tar], root: true)
        if (ret != 0) {
            Utils().showToast(true, local("STRAP_ERROR"))
            return
        }
        
        spawn(command: "\(inst_prefix)/usr/bin/chmod", args: ["4755", "\(inst_prefix)/usr/bin/sudo"], root: true)
        spawn(command: "\(inst_prefix)/usr/bin/chown", args: ["root:wheel", "\(inst_prefix)/usr/bin/sudo"], root: true)
        
        ret = spawn(command: "\(inst_prefix)/usr/bin/sh", args: ["\(inst_prefix)/prep_bootstrap.sh"], root: true)
        if (ret != 0) {
            Utils().showToast(true, local("STRAP_ERROR"))
            return
        }
        
        ret = spawn(command: "\(inst_prefix)/usr/bin/dpkg", args: ["-i", deb], root: true)
        if (ret != 0) {
            Utils().showToast(true, local("DPKG_ERROR"))
            return
        }
        
        ret = spawn(command: "\(inst_prefix)/usr/bin/uicache", args: ["-a"], root: true)
        if (ret != 0) {
            Utils().showToast(true, local("UICACHE_ERROR"))
            return
        }
        
        defaultSources(pm, rootful)
        Utils().showToast(false, local("INSTALL_DONE"))
    }
    
    
    // Reverting/Removing jailbreak, wipes /var/jb
    func revert(_ reboot: Bool) -> Void {
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
            print("[palera1n] Could not find helper?")
            return
        }
        
        let ret = spawn(command: helper, args: ["-f"], root: true)
        let rootful = ret == 0 ? false : true
        if !rootful {
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
            DispatchQueue.main.async {
                global.presentedViewController!.dismiss(animated: true) {
                    let loadingAlert = UIAlertController(title: nil, message: local("REMOVING"), preferredStyle: .alert)
                    let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
                    loadingAlert.view.addSubview(loadingIndicator)
                    loadingIndicator.hidesWhenStopped = true
                    loadingIndicator.startAnimating()
                    global.present(loadingAlert, animated: true, completion: nil)
                }
            }
            
            DispatchQueue.global(qos: .utility).async {
                let apps = try? FileManager.default.contentsOfDirectory(atPath: "/var/jb/Applications")
                for app in apps ?? [] {
                    if app.hasSuffix(".app") {
                        let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-u", "/var/jb/Applications/\(app)"], root: true)
                        if ret != 0 {Utils().showToast(true, local("REVERT_FAIL")); return}
                    }
                }
                
                let ret = spawn(command: helper, args: ["-r"], root: true)
                if ret != 0 {
                    Utils().showToast(true, local("REVERT_FAIL"))
                    return
                }
                    
                if (reboot) {
                    spawn(command: helper, args: ["-d"], root: true)
                } else {
                    Utils().showToast(false, local("REVERT_DONE"))
                }
            }
        }
    }
}





