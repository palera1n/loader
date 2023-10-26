//
//  Container.swift
//  palera1nLoader
//
//  Created by staturnz on 10/4/23.
//

import Foundation

public enum container_type {
    case application
    case plugin
    case xpc
}

public class container {
    public static let container_path = "/private/var/mobile/Containers/Data"
    public static let container_plist = ".com.apple.mobile_container_manager.metadata.plist"
    public static let bundle_key = "MCMMetadataIdentifier"

    public static func generate_hash() -> String {
        let hash_base = Array("xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxx")
        var hash_map = hash_base.map { String($0) }
        let char_list = "0123456789ABCDEF"

        for i in 0...hash_base.count - 1 {
            if (hash_map[i] == "x") {
                let offset = Int(arc4random_uniform(UInt32(char_list.count)))
                let start = char_list.startIndex
                
                let index = char_list.index(start, offsetBy: offset)
                hash_map[i] = String(char_list[index])
            }
        }
        return hash_map.joined(separator: "")
    }
    
    public static func container_with_identifer(_ bundle: String,_ type: container_type) -> String? {
        var search_path = container_path
        var hash = String()
        let fm = FileManager.default
        
        switch (type) {
        case .application:
            search_path += "/Application"
        case .plugin:
            search_path += "/PluginKitPlugin"
        case .xpc:
            search_path += "/XPCService"
        }
        
        if let contents = register_utils.dir_contents(search_path) {
            for container in contents {
                let plist_path = "\(search_path)/\(container)/\(container_plist)"
                var format: PropertyListSerialization.PropertyListFormat = .xml
                var plist_data: [String: Any]?
                if let data = fm.contents(atPath: plist_path) {
                    plist_data = try? PropertyListSerialization.propertyList(
                    from: data, options: [], format: &format) as? [String: Any]
                } else {
                    log(type: .error, msg: "failed to read plist data")
                    //return nil
                }
                
                guard let plist = plist_data else { return nil }
                guard let conatainer_bundle = plist[bundle_key] as? String else { return nil }
                if (conatainer_bundle == bundle) {
                    hash = container
                    break
                }
            }
        }
        
        if (hash.isEmpty) {
            log(type: .info, msg: "creating new hash for \(bundle)")
            hash = generate_hash()
        }
        
        return "\(search_path)/\(hash)"
    }

}
