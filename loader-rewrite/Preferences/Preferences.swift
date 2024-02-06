//
//  Preferences.swift
//  loader-rewrite
//
//  Created by samara on 1/29/24.
//

import Foundation

#warning("This is taken from https://github.com/NSAntoine/Antoine, thank you.")

/// A set of user controlled preferences.
enum Preferences {
    
    
    
    @Storage(key: "UserPreferredLanguageCode", defaultValue: nil, callback: preferredLangChangedCallback)
    /// Preferred language
    static var preferredLanguageCode: String?
    
    
    
    static var installPathChangedCallback: ((String?) -> Void)?
    @Storage(key: "UserSpecifiedInstallPath", defaultValue: "https://palera.in/loader.json")
    /// User specified download path
    static var installPath: String? {
        didSet { installPathChangedCallback?(installPath) }
    }

    static var defaultInstallPath: String { return _installPath.defaultValue! }
    
    
    
    @Storage(key: "UserSpecifiedRebootOnRevert", defaultValue: true)
    /// If the user wants to reboot when restoring system
    static var rebootOnRevert: Bool?
    
    
    
    @Storage(key: "OverrideConfigType", defaultValue: false)
    /// Override type get in configuration,, switch from `rootless => rootless`, `rootful => rootless` etc.
    static var overrideConfigType: Bool?
    
    @Storage(key: "UserSpecifiedDoDisplayPasswordPrompt", defaultValue: true)
    /// Show whether the psasword prompt is not displayed during installation, default will display the prompt for password
    static var doPasswordPrompt: Bool?
    
    
    
}

// MARK: - Callbacks
fileprivate extension Preferences {
    
    static func preferredLangChangedCallback(newValue: String?) {
        Bundle.preferredLocalizationBundle = .makeLocalizationBundle(preferredLanguageCode: newValue)
    }
}



// MARK: -



@propertyWrapper
struct Storage<Value> {
    typealias Callback = (Value) -> Void
    let key: String
    let defaultValue: Value
    let callback: Callback?
    
    init(key: String, defaultValue: Value, callback: Callback? = nil) {
        self.key = key
        self.defaultValue = defaultValue
        self.callback = callback
    }
    
    var wrappedValue: Value {
        get {
            if let storedValue = UserDefaults.standard.object(forKey: key) {
                if let castedValue = storedValue as? Value {
                    return castedValue
                }
            }
            return defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
            callback?(newValue)
        }
    }

}
