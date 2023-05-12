//
//  Bootstrap.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/12/23.
//

import Foundation
import UIKit

class bootstrap {

    // Ran after bootstrap/deb install
    func cleanUp() -> Void {
        deleteFile(file: "sileo.deb")
        deleteFile(file: "zebra.deb")
        deleteFile(file: "libkrw0-tfp0.deb")
        deleteFile(file: "bootstrap.tar")
        
        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
        
        do {
            let tmp = URL(string: NSTemporaryDirectory())!
            let tmpFile = try FileManager.default.contentsOfDirectory(at: tmp, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for url in tmpFile {try FileManager.default.removeItem(at: url)}}
        catch {
            return
        }
    }
    

    func installDebian(deb: String, completion: @escaping (String?, Int?) -> Void) {
        var ret = spawn(command: "/var/mobile/Library/palera1n/helper", args: ["-d", deb], root: true)
        if (ret != 0) {
            completion(local("DPKG_ERROR"), ret)
            return
        }

        ret = spawn(command: "\(envInfo.installPrefix)/usr/bin/uicache", args: ["-a"], root: true)
        if (ret != 0) {
            completion(local("ERROR_UICACHE"), ret)
            return
        }
        
        completion(local("DONE_INSTALL"), 0)
        return
    }
    
    
    func installBootstrap(tar: String, deb: String, completion: @escaping (String?, Int?) -> Void) {
        let debPath = "/var/mobile/Library/palera1n/downloads/\(deb)"
        var ret = spawn(command: "/var/mobile/Library/palera1n/helper", args: ["--install", tar, debPath], root: true)
        if (ret != 0) {
            completion(local("ERROR_UICACHE"), ret)
            return
        }
        
        ret = spawn(command: "\(envInfo.installPrefix)/usr/bin/uicache", args: ["-a"], root: true)
        if (ret != 0) {
            completion(local("ERROR_UICACHE"), ret)
            return
        }

        //cleanUp()
        completion(local("DONE_INSTALL"), 0)
        return
    }
}

