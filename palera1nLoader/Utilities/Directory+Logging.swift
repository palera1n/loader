//
//  Logging.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/28/23.
//

import Foundation
import os.log
import UIKit
// MARK: - make other dirs here
public enum LogType {
    case fatal
    case warning
    case info
    case error
}

public struct LogInfo {
    static let logPath: String = "/tmp/palera1n/logs"
    static var logFile: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMddyyyy-HH_mm"
        let formattedTimestamp = dateFormatter.string(from: Date())
        return "\(logPath)/\(formattedTimestamp)-loader.log"

    }
    static var isDebug: Bool {
        guard let procinfo = getProcInfo() else { return false }
        return (procinfo.kp_proc.p_flag & P_TRACED) != 0
    }
    static var isRelease: Bool = true
}

private func getProcInfo() -> kinfo_proc? {
    var procinfo = kinfo_proc()
    var size = MemoryLayout.stride(ofValue: procinfo)
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    let sysctl = sysctl(&mib, UInt32(mib.count), &procinfo, &size, nil, 0)
    
    if sysctl != 0 {
        log(type: .warning, msg: "sysctl failed, defaulting to non-debug")
        return nil
    }
    
    return procinfo
}

private func createLogDirectory() {
    do {
        try FileManager.default.createDirectory(atPath: LogInfo.logPath, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(atPath: "/tmp/palera1n/logs/temp", withIntermediateDirectories: true)
    } catch {
        log(type: .error, msg: "Failed to create log directory at: \(LogInfo.logPath)")
    }
}

private func createLogFile() {
    FileManager.default.createFile(atPath: LogInfo.logFile, contents: nil)
    log(type: .info, msg: "Created log file at: \(LogInfo.logFile)")
}

public func initLogs() {
    guard LogInfo.isRelease else { return }
    
    if LogInfo.isDebug {
        log(type: .info, msg: "Printing Debug Logs")
    }
    createLogDirectory()
    #if !targetEnvironment(simulator)
    createLogFile()
    #endif
}

public func log(type: LogType = .info, msg: String, viewController: UIViewController? = nil, file: String = #file, line: Int = #line, function: String = #function) {
    guard LogInfo.isRelease else { return }
    
    let srcFile = URL(string: file)?.lastPathComponent ?? "Unknown"
    
    #if !targetEnvironment(simulator)
    freopen(LogInfo.logFile.cString(using: .ascii)!, "a+", stderr)
    freopen(LogInfo.logFile.cString(using: .ascii)!, "a+", stdout)
    #endif
    
    let logMsg: String
    switch type {
    case .fatal, .error:
        logMsg = "[\(type)] \(msg)\tFile: \(srcFile):\(line)\n\tFunc: \(function)"
    case .warning, .info:
        logMsg = "[\(type)] \(msg)"
    }
    
    if type == .fatal {
        DispatchQueue.main.async {
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                let alert = UIAlertController.error(title: "\(type)", message: "\(logMsg)", actions: [])
                rootViewController.present(alert, animated: true)
            }
        }
    }
    
    
    print(logMsg, terminator: "\n")
}
