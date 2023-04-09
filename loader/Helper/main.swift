//
//  main.swift
//  palera1nHelper
//
//  Created by Staturnz on 04/08/2023.
//  Code based off of https://github.com/elihwyma/Pogo/blob/main/PogoHelper/main.swift by Amy While 
//

import Foundation
import SWCompression

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

func strap(_ input: String,_ rootless: Bool) {
    NSLog("[palera1n helper] Attempting to install \(input)")
    var dest = "/"
    var replace = ""
    
    if (rootless) {
        let active = "/private/preboot/active"
        let uuid: String
        do {uuid = try String(contentsOf: URL(fileURLWithPath: "/private/preboot/active"), encoding: .utf8) }
        catch { fatalError() }
        dest = "/private/preboot/\(uuid)/procursus"
        replace = "/var/jb"
    }
    
    do { try autoreleasepool {
        let data = try Data(contentsOf: URL(fileURLWithPath: input))
        let container = try TarContainer.open(container: data)
        NSLog("[palera1n helper] Opened Container")
        for entry in container { do {
            var path = entry.info.name
            if path.first == "." { path.removeFirst() }
            if path == "/" || path == "/var" { continue }
            path = path.replacingOccurrences(of: replace, with: dest)
            
            switch entry.info.type {
            case .symbolicLink:
                var linkName = entry.info.linkName
                if !linkName.contains("/") || linkName.contains("..") {
                    var tmp = path.split(separator: "/").map { String($0) }
                    tmp.removeLast()
                    tmp.append(linkName)
                    linkName = tmp.joined(separator: "/")
                    if linkName.first != "/" { linkName = "/" + linkName }
                }
                
                linkName = linkName.replacingOccurrences(of: replace, with: dest)
                NSLog("[palera1n helper] \(entry.info.linkName) at \(linkName) to \(path)")
                ln(path, linkName)
            case .directory:
                md(path, true)
            case .regular:
                guard let data = entry.data else { continue }
                try data.write(to: URL(fileURLWithPath: path))
            default:
                NSLog("[palera1n helper] Unknown Action for \(entry.info.type)")
            }
            
            var attrib = [FileAttributeKey: Any]()
            attrib[.posixPermissions] = entry.info.permissions?.rawValue
            attrib[.ownerAccountName] = entry.info.ownerUserName
            var ownerGroupName = entry.info.ownerGroupName
            if ownerGroupName == "staff" && entry.info.ownerUserName == "root" { ownerGroupName = "wheel" }
            attrib[.groupOwnerAccountName] = ownerGroupName
            do { try fm.setAttributes(attrib, ofItemAtPath: path) }
            catch { continue }
        } catch { NSLog("[palera1n helper] Error: \(error.localizedDescription)") }}}
    } catch { NSLog("[palera1n helper] Error: \(error.localizedDescription)"); return }
    
    NSLog("[palera1n helper] Strapped to \(dest)")
    if (rootless) {if !fm.fileExists(atPath: "/var/jb") { ln("/var/jb", dest )}}
    var attrib = [FileAttributeKey: Any]()
    attrib[.posixPermissions] = 0o755
    attrib[.ownerAccountName] = "mobile"
    attrib[.groupOwnerAccountName] = "mobile"
    do { try fm.setAttributes(attrib, ofItemAtPath: "\(replace)/var/mobile")}
    catch { NSLog("[palera1n helper] Failed to set attributes: \(error.localizedDescription)") }
}

func main() {
    NSLog("[palera1n helper] Spawned!")
    guard getuid() == 0 else { fatalError() }
    let rootfulCheck = check_rootful() == 1 ? true : false
    let forceRevertCheck = check_forcerevert() == 1 ? true : false
    var args = CommandLine.arguments

    if (args[1] == "-i") {
        if (!rootfulCheck) {strap(args[2], true)}
        else {strap(args[2], false)}
    } else if (args[1] == "-r") {
        if !rootfulCheck {
            let uuid: String
            do {uuid = try String(contentsOf: URL(fileURLWithPath: "/private/preboot/active"), encoding: .utf8)
            } catch {fatalError()}
            rm("/private/preboot/\(uuid)/procursus")
            rm("/var/jb")
        }
    } else if (args[1] == "-f") {
        if rootfulCheck { fatalError() }
    } else if (args[1] == "-n") {
        if rootfulCheck && forceRevertCheck { fatalError() }
    } else {
        NSLog("[palera1n helper] Invalid argument")
    }
}

main()
