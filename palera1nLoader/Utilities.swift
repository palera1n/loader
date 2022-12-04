//
//  Utilities.swift
//  palera1nLoader
//
//  Created by Lakhan Lothiyi on 28/11/2022.
//

import Foundation
import SwiftUI


class utils {
    
    static func respring() {
        guard let window = UIApplication.shared.windows.first else { fatalError() }
        while true {
            window.snapshotView(afterScreenUpdates: false)
        }
    }
}
