//
//  Bootstrap.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/12/23.
//

import Foundation
import UIKit

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

func defaultSources(_ pm: String,_ rootful: Bool) -> Void {
    let inst_prefix = rootful ? "" : "/var/jb"
    let zebraSources = "/var/mobile/Library/Application Support/xyz.willy.Zebra/sources.list"
    let sileoSources = "\(inst_prefix)/etc/apt/sources.list.d/procursus.sources"
    let sileoLine = "Types: deb\nURIs: https://repo.getsileo.app/\nSuites: ./\nComponents:\n"
    let zebraLine = "deb https://getzbra.com/repo/ ./\n"
    
    let version = ProcessInfo().operatingSystemVersion.majorVersion
    let CF = version == 16 ? "1900" : "1800"
    
    var (readBelow,fixCFStr) = (false,false)
    var (oldCF,readPath,dataToWrite) = ("","","")
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
        palestrapLine = "deb https://strap.palera.in// iphoneos-arm64/\(CF) main\n"
    }
    
    guard let fd = fopen(readPath, "r") else { return }
    defer { fclose(fd) }

    while let line = readLine() {
        if (pm == "sileo") {
            if (readBelow) {
                if (line == "Suites: 1900" && CF != "1900") { fixCFStr = true;oldCF = "1900" }
                else if (line == "Suites: 1800" && CF != "1800") { fixCFStr = true;oldCF = "1800" }
                else { fixCFStr = false }
                readBelow = false
            }
            if (line == "URIs: https://apt.procurs.us/") {procursusStap = true;readBelow = true}
            if (line == "URIs: https://repo.palera.in/") {palera1nRepo = true}
            if (line == "URIs: https://ellekit.space/") {ellekitRepo = true}
            if (line == "URIs: https://strap.palera.in/") {palera1nStrap = true}
            if (line == "URIs: https://repo.getsileo.app/") {sileoRepo = true}

        } else {
            if (line.hasPrefix("deb https://apt.procurs.us/")) {procursusStap = true;}
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
    if (fixCFStr) {dataToWrite = dataToWrite.replacingOccurrences(of: oldCF, with: CF)}
    let docUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let tempFile = docUrl.appendingPathComponent("sources")
    try? dataToWrite.write(to: tempFile, atomically: true, encoding: String.Encoding.utf8)
    _ = spawn(command: "\(inst_prefix)/usr/bin/mv", args: [tempFile.path, readPath], root: true)
}

func installDeb(_ file: String,_ rootful: Bool) -> Void {
    let group = DispatchGroup()
    group.enter()
    DispatchQueue.global(qos: .default).async {
        download("\(file).deb", rootful)
        group.leave()
    }
    group.wait()
    spinnerAlert("INSTALLING", start: true)
    let inst_prefix = rootful ? "" : "/var/jb"
    let deb = "\(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(file).deb").path)" // gross
    
    var ret = spawn(command: "\(inst_prefix)/usr/bin/dpkg", args: ["-i", deb], root: true)
    if (ret != 0) {
        spinnerAlert("INSTALLING", start: false)
        errAlert(title: local("DPKG_ERROR"), message: "Status: \(ret)")
        return
    }
    
    ret = spawn(command: "\(inst_prefix)/usr/bin/uicache", args: ["-a"], root: true)
    if (ret != 0) {
        spinnerAlert("INSTALLING", start: false)
        errAlert(title: local("UICACHE_ERROR"), message: "Status: \(ret)")
        return
        
    }
    defaultSources(file, rootful)
    sleep(1)
    spinnerAlert("INSTALLING", start: false)
    errAlert(title: local("INSTALL_DONE"), message: local("ENJOY"))
}
        
    
func bootstrap(_ rootful: Bool) -> Void {
    guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
        print("[palera1n] Could not find helper?")
        return
    }
    let inst_prefix = rootful ? "/" : "/var/jb"
    let tar = "\(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("bootstrap.tar").path)"

    let group = DispatchGroup()
    group.enter()
    DispatchQueue.global(qos: .default).async {
        download("bootstrap.tar", rootful)
        group.leave()
    }
    group.wait()
    
    spinnerAlert("INSTALLING", start: true)
    spawn(command: "/sbin/mount", args: ["-uw", "/preboot"], root: true)
    if rootful { spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)}
    var ret = spawn(command: helper, args: ["-i", tar], root: true)
    spawn(command: "\(inst_prefix)/usr/bin/chmod", args: ["4755", "\(inst_prefix)/usr/bin/sudo"], root: true)
    spawn(command: "\(inst_prefix)/usr/bin/chown", args: ["root:wheel", "\(inst_prefix)/usr/bin/sudo"], root: true)
    
    if (ret != 0) {
        spinnerAlert("INSTALLING", start: false)
        errAlert(title: local("STRAP_ERROR"), message: "Status: \(ret)")
        return
    }
    
    ret = spawn(command: "\(inst_prefix)/usr/bin/sh", args: ["\(inst_prefix)/prep_bootstrap.sh"], root: true)
    if (ret != 0) {
        spinnerAlert("INSTALLING", start: false)
        errAlert(title: local("STRAP_ERROR"), message: "Status: \(ret)")
        return
    }
    
    spinnerAlert("INSTALLING", start: false)
}

func combo(_ file: String,_ rootful: Bool) -> Void {
    DispatchQueue.global(qos: .utility).async { [] in
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .default).async {
            bootstrap(rootful)
            group.leave()
        }
        group.wait()
        installDeb(file, rootful)
    }
}

func revert(_ reboot: Bool) -> Void {
    guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
        print("[palera1n] Could not find helper?");return
    }
    
    let ret = spawn(command: helper, args: ["-f"], root: true)
    let rootful = ret == 0 ? false : true
    if !rootful {
        spinnerAlert("REMOVING", start: true)
        DispatchQueue.global(qos: .utility).async {
            let apps = try? FileManager.default.contentsOfDirectory(atPath: "/var/jb/Applications")
            for app in apps ?? [] {
                if app.hasSuffix(".app") {
                    let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-u", "/var/jb/Applications/\(app)"], root: true)
                    if ret != 0 {errAlert(title: "Failed to unregister \(app)", message: "Status: \(ret)"); return}
                }
            }
            
            let ret = spawn(command: helper, args: ["-r"], root: true)
            if ret != 0 {
                errAlert(title: local("REVERT_FAIL"), message: "Status: \(ret)")
                print("[revert] Failed to remove jailbreak: \(ret)")
                return
            }
                
            sleep(1)
            if (reboot) {
                spawn(command: helper, args: ["-d"], root: true)
            } else {
                spinnerAlert("REMOVING", start: false)
                errAlert(title: local("REVERT_DONE"), message: local("CLOSE_APP"))
            }
        }
    }
}
