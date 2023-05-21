//
//  Logging.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/28/23.
//

import Foundation

enum logTypes {
    case fatal
    case debug
    case warning
    case info
    case error
}

struct logInfo {
    static var logPath: String = "/var/mobile/Library/palera1n/logs"
    static var logFile: String = ""
    static var isDebug: Bool = false
    static var isRelease: Bool = false
}

func errorString(_ error: Int32) -> String {
    if (error > 106) {
        return "\(POSIXError(POSIXErrorCode(rawValue: (Int32(error/256)))!))"
    }
    return "\(POSIXError(POSIXErrorCode(rawValue: error)!))"
}

// Creates new log file, check if debugging device
func initLogs() -> Void {
    var procinfo = kinfo_proc()
    var size = MemoryLayout.stride(ofValue: procinfo)
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    let sysctl = sysctl(&mib, UInt32(mib.count), &procinfo, &size, nil, 0)
    
    if (sysctl != 0) {
        NSLog("[WARNING] sysctl failed, defaulting to non-debug")
        logInfo.isDebug = false
    } else {
        let isDebug = procinfo.kp_proc.p_flag & P_TRACED
        if (isDebug != 0) {
            NSLog("[INFO] Printing Debug Logs")
            logInfo.isDebug = true
        } else {
            logInfo.isDebug = false
        }
    }
    
    do {
        try FileManager.default.createDirectory(atPath: "/var/mobile/Library/palera1n/logs", withIntermediateDirectories: true)
    } catch {
        NSLog("[ERROR] Failed to created log directory at: /var/mobile/Library/palera1n/logs")
    }
    
    let timestamp = NSDate().timeIntervalSince1970
    FileManager.default.createFile(atPath: "/var/mobile/Library/palera1n/logs/\(timestamp)-loader.log", contents: nil)
    NSLog("[INFO] Created log file at: /var/mobile/Library/palera1n/logs/\(timestamp)-loader.log")
    logInfo.logFile = "/var/mobile/Library/palera1n/logs/\(timestamp)-loader.log"
}

// Prints log message with type
func log(type: logTypes = .info, msg: String, file: String = #file, line: Int = #line, function: String = #function) {
    let srcFile = URL(string: file)!.lastPathComponent
    freopen(logInfo.logFile.cString(using: .ascii)!, "a+", stderr)
    freopen(logInfo.logFile.cString(using: .ascii)!, "a+", stdout)
    
    switch (type) {
    case .fatal:
        print("[FATAL] \(msg)\tFile: \(srcFile):\(line)\n\tFunc: \(function)", terminator: "\n")
    case .debug:
        print("[DEBUG] \(msg)tFile: \(srcFile):\(line)\n\tFunc: \(function)", terminator: "\n")
    case .warning:
        print("[WARNING] \(msg)", terminator: "\n")
    case .info:
        print("[INFO] \(msg)", terminator: "\n")
    case .error:
        print("[ERROR] \(msg)\tFile: \(srcFile):\(line)\n\tFunc: \(function)", terminator: "\n")
    }
}
