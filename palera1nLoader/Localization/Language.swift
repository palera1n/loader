//
//  Language.swift
//  Antoine
//
//  Created by Serena on 24/02/2023.
//

import Foundation

struct Language {
    static var availableLanguages: [Language] {
        return Bundle.main.localizations.compactMap { languageCode in
            // Skip over 'Base', it means nothing
            guard languageCode != "Base",
                  let subtitle = Locale.current.localizedString(forLanguageCode: languageCode) else {
                return nil
            }
            
            let displayLocale = Locale(identifier: languageCode)
            guard let displayName = displayLocale.localizedString(forLanguageCode: languageCode)?.capitalized(with: displayLocale) else {
                return nil
            }
            
            return Language(displayName: displayName, subtitleText: subtitle, languageCode: languageCode)
        }
    }
    
    /// The display name, being the language's name in itself, such as 'русский' in Russian
    let displayName: String
    
    /// The subtitle, being the language's name in the current language,
    /// such as 'Russian' when the user is currently using English.
    let subtitleText: String
    
    /// The language code, such as 'ru'
    let languageCode: String
}
