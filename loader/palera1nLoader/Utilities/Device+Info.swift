//
//  Device.swift
//  palera1nLoader
//
//  Created by samara on 12/21/23.
//

import Foundation
import Extras

public class VersionSeeker {
    static var corefoundationVersionShort = Int(floor(kCFCoreFoundationVersionNumber / 100) * 100)
    static func deviceBoot_Args() -> String {
        var size: size_t = 0
        sysctlbyname("kern.bootargs", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("kern.bootargs", &machine, &size, nil, 0)
        let bootArgs = String(cString: machine)
        return bootArgs
    }
    
    static func kernelVersion() -> String {
        var utsnameInfo = utsname()
        uname(&utsnameInfo)
        
        let releaseCopy = withUnsafeBytes(of: &utsnameInfo.release) { bytes in
            Array(bytes)
        }
        
        let version = String(cString: releaseCopy)
        return version
    }
    
    // iPhone12,1 etc
    static func deviceId() -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
        if modelCode!.contains("arm64") || modelCode!.contains("x86_64") {
            return "Simulated"
        }
        return modelCode
    }
    
    // Gets the boot manifest hash for iOS 14+ only, this will only be useful for non-Rootful jailbreaks
    static func bootmanifestHash() -> String? {
        let registryEntry = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/chosen")
        
        guard let bootManifestHashUnmanaged = IORegistryEntryCreateCFProperty(registryEntry, "boot-manifest-hash" as CFString, kCFAllocatorDefault, 0),
              let bootManifestHash = bootManifestHashUnmanaged.takeRetainedValue() as? Data else {
            return nil
        }
        
        return bootManifestHash.map { String(format: "%02X", $0) }.joined()
    }
}
