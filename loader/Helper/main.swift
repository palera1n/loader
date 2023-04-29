//
//  main.swift
//  palera1nHelper
//
//  Created by Staturnz on 04/08/2023.
//  Code based off of https://github.com/elihwyma/Pogo/blob/main/PogoHelper/main.swift by Amy While 
//

import Foundation

let fm = FileManager.default
func md(_ at: String,_ wid: Bool) {
    try? fm.createDirectory(atPath: at, withIntermediateDirectories: wid)
}

func ln(_ target: String,_ dest: String) {
    do { try fm.createSymbolicLink(atPath: target, withDestinationPath: dest) }
    catch { NSLog("[palera1n helper] Failed to make link"); fatalError() }
}

func rm(_ at: String) {
    do { try fm.removeItem(at: URL(fileURLWithPath:at)) }
    catch { NSLog("[palera1n helper] Failed with error \(error.localizedDescription)") }
}

func touch(atPath path: String) {
    let fileData = Data()
    fm.createFile(atPath: path, contents: fileData, attributes: nil)
}


func removeLeftovers() {
    let remove = ["/var/jb","/var/lib","/var/cache","/var/LIB","/var/Liy","/var/LIY","/var/sbin","/var/bin","/var/ubi","/var/ulb","/var/local"]
    for path in remove {
        rm(path)
    }
}

func revert() -> Void {
    let rootfulCheck = check_rootful() == 1 ? true : false
    if !rootfulCheck {
        let uuid: String
        do {
            uuid = try String(contentsOf: URL(fileURLWithPath: "/private/preboot/active"), encoding: .utf8)
        } catch {
            fatalError("Failed to retrieve UUID: \(error.localizedDescription)")
        }

        let directoryPath = "/private/preboot/\(uuid)"
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(atPath: directoryPath)
            for file in files {
                if file.hasPrefix("jb-") {
                    let folderToDelete = "\(directoryPath)/\(file)"
                    do {
                        try fileManager.removeItem(atPath: folderToDelete)
                        NSLog("[palera1n helper] Folder deleted successfully: \(folderToDelete)")
                    } catch {
                        NSLog("[palera1n helper] Failed to delete folder: \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            NSLog("[palera1n helper] Failed to retrieve contents of directory: \(error.localizedDescription)")
        }

        removeLeftovers()
        rm("/private/preboot/\(uuid)/procursus") // old installs
    }
}

func main() -> __uint32_t? {
    guard getuid() == 0 else { fatalError() }
    let rootfulCheck = check_rootful() == 1 ? true : false
    let forceRevertCheck = check_forcerevert() == 1 ? true : false
    var args = CommandLine.arguments

    switch (args[1]) {
    case "-r":
        revert()
    case "-q":
        get_kflags()
        return 0
    case "-g":
        get_pflags()
        return 0
    case "-p":
        setpw(&args[2])
    case "-e":
        if !rootfulCheck {
            if !fm.fileExists(atPath: "/var/jb") {
                ln("/var/jb", args[2])
            }
        }
    case "-h":
        get_bmhash()
    case "-f":
        if rootfulCheck { exit(1) }
    case "-n":
        if rootfulCheck && forceRevertCheck { exit(1) }
    case "-d":
        reboot(0)
    default:
        NSLog("[Helper] Unknown Argument")
    }
    return 0
}

main()
