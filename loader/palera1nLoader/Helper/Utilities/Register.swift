//
//  Register.swift
//  palera1nLoader
//
//  Created by staturnz on 10/4/23.
//

import Foundation
import ObjectiveC
import Darwin

public enum container_types {
    case application
    case plugin
}

public var LSAppWorkspace: AnyClass!
public var defaultWorkspace: AnyObject!

@objc private protocol LSApplicationWorkspace {
    static func defaultWorkspace() -> Self
    func openApplication(withBundleID arg1: String) -> Bool
    func unregisterApplication(_ application: NSURL) -> Bool
    func registerApplicationDictionary(_ applicationDictionary: NSDictionary) -> Bool
    func _LSPrivateRebuildApplicationDatabasesForSystemApps(_ arg1: Bool, internal arg2: Bool, user arg3: Bool) -> Bool
}

public class register_utils {
    public static func get_str_from_plist(_ path: String,_ key: String) -> String? {
        var fmt: PropertyListSerialization.PropertyListFormat = .xml
        if let data = FileManager.default.contents(atPath: path) {
            if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: &fmt) as? [String: Any] {
                return plist[key] as? String
            }
        }
        return nil
    }

    public static func resolve_symlinks(_ path: String) -> String {
        let app_path = URL(fileURLWithPath: path)
        return app_path.resolvingSymlinksInPath().path
    }

    public static func dir_contents(_ path: String) -> [String]? {
        return try? FileManager.default.contentsOfDirectory(atPath: path)
    }

    @discardableResult
    public static func notify_post(_ name: String) -> __uint32_t {
        let RTLD_DEFAULT = UnsafeMutableRawPointer(bitPattern: -2)
        let notify_post_symbol = dlsym(RTLD_DEFAULT, "notify_post")
        if (notify_post_symbol != nil) {
            typealias func_alias = @convention(c) (_ name: String) -> __uint32_t
            let function = unsafeBitCast(notify_post_symbol, to: func_alias.self)
            return function(name)
        }
        return 1
    }
}

public func init_LSApplicationWorkspace() -> Bool {
    guard let _LSAppWorkspace = NSClassFromString("LSApplicationWorkspace") else {
        log(type: .error, msg: "failed to find the LSApplicationWorkspace class.")
        return false
    }
    LSAppWorkspace = _LSAppWorkspace

    guard let _defaultWorkspace = (LSAppWorkspace as AnyObject).perform(
        NSSelectorFromString("defaultWorkspace"))?.takeUnretainedValue() else {
        log(type: .error, msg: "failed to get the defaultWorkspace.")
        return false
    }
    defaultWorkspace = _defaultWorkspace
    return true
}

private func rebuild_application_database() -> Int32 {
    if(!init_LSApplicationWorkspace()) {
        log(type: .error, msg: "failed to initialize LSApplicationWorkspace")
        return -1
    }

    let selector = NSSelectorFromString("_LSPrivateRebuildApplicationDatabasesForSystemApps:internal:user:")
    if defaultWorkspace.responds(to: selector) {
        let method = class_getMethodImplementation(LSAppWorkspace, selector)
        typealias f = @convention(c) (AnyObject, Selector, Bool, Bool, Bool) -> Bool
        if (!unsafeBitCast(method, to: f.self)(defaultWorkspace, selector, true, true, false)) {
            log(type: .error, msg: "failed to rebuild system applications database")
            return -1
        }

        return 0
    }

    log(type: .error, msg: "failed to respond to _LSPrivateRebuildApplicationDatabasesForSystemApps")
    return -1
}

public func register(_ path: String) -> Bool {
    if(!init_LSApplicationWorkspace()) {
        log(type: .error, msg: "failed to initialize LSApplicationWorkspace")
        return false
    }
    
    let resolved_path = register_utils.resolve_symlinks(path)
    let info_plist = "\(resolved_path)/Info.plist"
    let plugins_path = "\(resolved_path)/PlugIns"

    if (!resolved_path.hasPrefix("/Applications")) {
        log(type: .error, msg: "Application must be a system app in /Applications")
        return false
    }

    guard let bundle_id = register_utils.get_str_from_plist(info_plist, "CFBundleIdentifier") else { return false }
    guard let container_path = container.container_with_identifer(bundle_id, .application) else {
        log(type: .error, msg: "Failed to find/create container path for: \(bundle_id)")
        return false
    }

    let plist = NSMutableDictionary()
    plist.setObject("System", forKey: "ApplicationType" as NSCopying)
    plist.setObject(1, forKey: "BundleNameIsLocalized" as NSCopying)
    plist.setObject(bundle_id, forKey: "CFBundleIdentifier" as NSCopying)
    plist.setObject(0, forKey: "CompatibilityState" as NSCopying)
    plist.setObject(container_path, forKey: "Container" as NSCopying)
    plist.setObject(0, forKey: "IsDeletable" as NSCopying)
    plist.setObject(resolved_path, forKey: "Path" as NSCopying)

    let bundle_plugins = NSMutableDictionary()
    if let plugins = register_utils.dir_contents(plugins_path) {
        for name in plugins {
            let full_path = "\(plugins_path)/\(name)"
            let plugin_info_plist = "\(full_path)/Info.plist"
            
            guard let plugin_id = register_utils.get_str_from_plist(plugin_info_plist, "CFBundleIdentifier") else { return false }
            guard let plugin_container_path = container.container_with_identifer(plugin_id, .plugin) else {
                log(type: .error, msg: "Failed to find/create container path for: \(bundle_id)")
                return false
            }

            let plugin_plist = NSMutableDictionary()
            plugin_plist.setObject("PluginKitPlugin", forKey: "ApplicationType" as NSCopying)
            plugin_plist.setObject(1, forKey: "BundleNameIsLocalized" as NSCopying)
            plugin_plist.setObject(plugin_id, forKey: "CFBundleIdentifier" as NSCopying)
            plugin_plist.setObject(0, forKey: "CompatibilityState" as NSCopying)
            plugin_plist.setObject(plugin_container_path, forKey: "Container" as NSCopying)
            plugin_plist.setObject(full_path, forKey: "Path" as NSCopying)
            plugin_plist.setObject(bundle_id, forKey: "PluginOwnerBundleID" as NSCopying)
            bundle_plugins.setObject(plugin_plist, forKey: plugin_id as NSCopying)
        }
    }

    plist.setObject(bundle_plugins, forKey: "_LSBundlePlugins" as NSCopying)
    let selector = NSSelectorFromString("registerApplicationDictionary:")
    let method = class_getMethodImplementation(LSAppWorkspace, selector)

    typealias f = @convention(c) (AnyObject, Selector, NSDictionary) -> Bool
    if (!unsafeBitCast(method, to: f.self)(defaultWorkspace, selector, plist)) {
        log(type: .error, msg: "Failed to register application")
        return false
    }

    register_utils.notify_post("com.apple.mobile.application_installed");
    return true
}

public func unregister(_ path: String) -> Bool {
    if(!init_LSApplicationWorkspace()) {
        log(type: .error, msg: "Failed to initialize LSApplicationWorkspace")
        return false
    }
    
    let resolved_path = register_utils.resolve_symlinks(path)
    let url = NSURL(fileURLWithPath: resolved_path)

    if (!resolved_path.hasPrefix("/Applications")) {
        log(type: .error, msg: "Application must be a system app in /Applications")
        return false
    }

    let selector = NSSelectorFromString("unregisterApplication:")
    let method = class_getMethodImplementation(LSAppWorkspace, selector)

    typealias f = @convention(c) (AnyObject, Selector, NSURL) -> Bool
    if (!unsafeBitCast(method, to: f.self)(defaultWorkspace, selector, url)) {
        log(type: .error, msg: "Failed to unregister application (might already be unregistered)")
        return false
    }
    return true
}
