//
//  Decoder.swift
//  palera1nLoader
//
//  Created by Staturnz on 6/7/23.
//

import Foundation


// loader.json
public struct loaderJSON: Codable {
    let bootstraps: [Bootstrap]
    let managers: [Manager]
    let assets: [Asset]
}

// Bootstrap
struct Bootstrap: Codable {
    let label: String
    let items: [BootstrapItem]
}

// BootstrapItem
struct BootstrapItem: Codable {
    let cfver: String
    let uri: String
}

// Manager
struct Manager: Codable {
    let label: String
    let items: [ManagerItem]
}

// ManagerItem
struct ManagerItem: Codable {
    let name: String
    let uri: String
    let icon: String
    let filePaths: [String] // Updated the type to [String]
}

struct Asset: Codable {
    let label: String
    let repositories: [AssetRepository]
    let packages: [String]
}

struct AssetRepository: Codable {
    let uri: String
    let suite: String
    let component: String
}


public struct cellInfo {
    let names: [String]
    let icons: [String]
    let paths: [String]
}

public func getBootstrapURL(_ json: loaderJSON) -> String? {
    let jailbreakType = envInfo.isRootful ? "Rootful" : "Rootless"
    let cfver = String(envInfo.CF)
    var items: [BootstrapItem]?
    
    for type in json.bootstraps {
        if (type.label == jailbreakType) {
            items = type.items
        }
    }
    
    if (items == nil) {
        log(type: .error, msg: "Failed to find bootstrap url.")
        return nil
    }

    for bootstrap in items! {
        if (bootstrap.cfver == cfver) {
            return bootstrap.uri
        }
    }
    
    return nil
}

public func getManagerURL(_ json: loaderJSON,_ pkgMgr: String) -> String? {
    let jailbreakType = envInfo.isRootful ? "Rootful" : "Rootless"
    var items: [ManagerItem]?
    
    for type in json.managers {
        if (type.label == jailbreakType) {
            items = type.items
        }
    }
    
    if (items == nil) {
        log(type: .error, msg: "Failed to find package manager info.")
        return nil
    }
    
    for info in items! {
        if (info.name.lowercased() == pkgMgr.lowercased()) {
            return String(info.uri)
        }
    }
    
    return nil
}

public func getAssetsInfo(_ json: loaderJSON) -> (repositories: [String], packages: [String])? {
    let jailbreakType = envInfo.isRootful ? "Rootful" : "Rootless"
    var packages: [String] = []
    var repositories: [String] = []

    for asset in json.assets {
        if asset.label == jailbreakType {
            packages = asset.packages
            for repository in asset.repositories {
                let repositoryInfo = "Types: deb\nURI: \(repository.uri)\nSuite: \(repository.suite)\nComponent: \(repository.component)\n\n"
                repositories.append(repositoryInfo)
            }
        }
    }

    if packages.isEmpty && repositories.isEmpty {
        log(type: .error, msg: "Failed to find assets info for \(jailbreakType).")
        return nil
    }

    return (packages, repositories)
}




public func getCellInfo(_ json: loaderJSON) -> cellInfo? {
    let jailbreakType = envInfo.isRootful ? "Rootful" : "Rootless"
    //let jailbreakType = "Rootful"
    var items: [ManagerItem]?
    var names: [String] = []
    var icons: [String] = []
    var paths: [String] = []

    for type in json.managers {
        if (type.label == jailbreakType) {
            items = type.items
        }
    }
    
    if (items == nil) {
        log(type: .error, msg: "Failed to find package manager info.")
        return nil
    }
    
    for info in items! {
        names.append(info.name)
        icons.append(info.icon)
        
        let filePathString = info.filePaths.joined(separator: ", ")
        paths.append(filePathString)
    }
    
    if (names.isEmpty || icons.isEmpty) {
        log(type: .error, msg: "Failed to find package manager info.")
        return nil
    }
    
    return cellInfo(names: names, icons: icons, paths: paths)
}
