//
//  paleinfo.swift
//  palera1nLoader
//
//  Created by staturnz on 5/1/23.
//

import Foundation
import Extras
import MachO

class paleinfo {
    
    let checkrain_option_safemode: Int = (1 << 0) // 1
    let checkrain_option_bind_mount: Int = (1 << 1) // 2
    let checkrain_option_overlay: Int = (1 << 2) // 4
    let checkrain_option_force_revert: Int = (1 << 7) // 128
    
    let palerain_option_rootful: Int = (1 << 0) // 1
    let palerain_option_jbinit_log_to_file: Int = (1 << 1) // 2
    let palerain_option_setup_rootful: Int = (1 << 2)  // 4
    let palerain_option_setup_rootful_forced: Int = (1 << 3) // 8
    
    struct paleinfo {
        static var kinfo_flags: Int = 0
        static var pinfo_flags: Int = 0
        static var kinfo_flags_str: String = ""
        static var pinfo_flags_str: String = ""
    }
    
    @discardableResult func p1ctl(_ arg: String) -> Int {
        return spawn(command: "/cores/binpack/usr/sbin/p1ctl", args: [arg], root: true)
    }
    
    func checkRootful() -> Bool {
        return (paleinfo.kinfo_flags & checkrain_option_force_revert) != 0;
    }
    
    func checkForceRevert() -> Bool {
        return (paleinfo.pinfo_flags & palerain_option_rootful) != 0;
    }
    
    func getFlags() -> Void {
        if (fileExists("/cores/binpack/usr/sbin/p1ctl")) {
            var ret = p1ctl("palera1n_flags")
            if (ret != 0) {
                log(type: .fatal, msg: "p1ctl returned with an error: \(ret)")
                return
            }
            
            ret = p1ctl("checkra1n_flags")
            if (ret != 0) {
                log(type: .fatal, msg: "p1ctl returned with an error: \(ret)")
                return
            }
            
            
        } else {
            log(type: .fatal, msg: "Unable to find p1ct1")
            return
        }
    }
    
    func set_pw(pw: String) -> Void {
        var fd: [Int32] = [0,0]
        let bin = envInfo.isRootful ? "/usr/sbin/pw" : "/var/jb/usr/sbin/pw"
        
        if pipe(&fd[0]) == -1 {
            return
        }
        
        write(fd[1], pw, strlen(pw) + 1)
        dup2(fd[0], STDIN_FILENO)
        close(fd[0])
        close(fd[1])
        
        spawn(command: bin, args: ["usermod", "501", "-h", "0"], root: true)
    }
    
    func get_bmhash() -> String? {
#if targetEnvironment(simulator)
        log(msg: "Skiping bmhash on simulator")
#else
        let chosen = IORegistryEntryFromPath(0, "IODeviceTree:/chosen")
        if (chosen == MACH_PORT_NULL) { return nil }
        
        guard let manifestHash = IORegistryEntryCreateCFProperty(chosen, "boot-manifest-hash" as CFString, kCFAllocatorDefault, 0) else {
            return nil
        }
        IOObjectRelease(chosen);
        guard let manifestHashData = manifestHash.takeRetainedValue() as? Data else {
            return nil
        }
        return manifestHashData.map { String(format: "%02X", $0) }.joined()
        
#endif
        return nil
    }
}
