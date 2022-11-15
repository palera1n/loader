//
//  SysInfo.swift
//  palera1nLoader
//
//  Created by Lakhan Lothiyi on 11/11/2022.
//

import Foundation

func uname() -> String {
    var unameData = utsname()
    uname(&unameData)
    let machineMirror = Mirror(reflecting: unameData.version)
    let unamestr = machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8 , value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }
    return unamestr
}
