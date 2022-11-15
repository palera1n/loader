//
//  Console.swift
//  Palera1nApp
//
//  Created by Lakhan Lothiyi on 08/11/2022.
//

import Foundation
import SwiftUI

class Console: ObservableObject {
    @Published var consoleData: [LogItem] = []
    
    public func log(_ str: String) {
        let item = LogItem(type: .log, string: str)
        consoleData.append(item)
    }
    
    public func warn(_ str: String) {
        let item = LogItem(type: .warning, string: str)
        consoleData.append(item)
    }
    
    public func error(_ str: String) {
        let item = LogItem(type: .error, string: str)
        consoleData.append(item)
    }
    
    public func success(_ str: String) {
        let item = LogItem(type: .success, string: str)
        consoleData.append(item)
    }
    
    public func clear() {
        consoleData = []
    }
    
    static func logTypeToColor(_ type: LogType) -> Color {
        switch type {
        case .log:
            return Color.white
        case .warning:
            return Color.yellow
        case .error:
            return Color.red
        case .success:
            return Color.green
        }
    }
}


struct LogItem: Identifiable {
    var id = UUID()
    let type: LogType
    let string: String
}


enum LogType {
    case log // white
    case warning // yellow
    case error // red
    case success // green
}
