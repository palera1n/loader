//
//  Constants.swift
//  palera1nLoader
//
//  Created by Lakhan Lothiyi on 11/11/2022.
//

import Foundation
import SwiftUI

func palera1nColorGradients() -> [Color] {
    if UIDevice.current.systemVersion.contains("15") {
        return [.init(hex: "071B33"), .init(hex: "833F46"), .init(hex: "FFB123")] // iOS 15 color palette
    } else if UIDevice.current.systemVersion.contains("16") {
        return [.init(hex: "4a67d4"), .init(hex: "8dd1c5"), .init(hex: "edd6ab"), .init(hex: "269dd4"), .init(hex: "f2da65")] // iOS 16 color palette
    }
    return [.init(hex: "000000")]
}

func palera1nColorTB() -> String {
    if UIDevice.current.systemVersion.contains("15") {
        return "442223" // iOS 15 color palette
    } else if UIDevice.current.systemVersion.contains("16") {
        return "3d4c47" // iOS 16 color palette
    }
    return "000000"
}
