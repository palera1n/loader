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
    deleteFile(file: "libkrw0-tfp0.deb")
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


