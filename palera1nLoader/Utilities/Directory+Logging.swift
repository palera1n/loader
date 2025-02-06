//
//  Logging.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/28/23.
//

import Foundation
import os.log
import UIKit
// MARK: - make other dirs here
public enum LogType {
    case fatal
    case warning
    case info
    case error
}

public func log(type: LogType = .info, msg: String, viewController: UIViewController? = nil, file: String = #file, line: Int = #line, function: String = #function) {
    if type == .fatal {
        DispatchQueue.main.async {
            if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
                let alert = UIAlertController.error(title: "\(type)", message: "\(msg)", actions: [])
                rootViewController.present(alert, animated: true)
            }
        }
    }
    
    
    print(msg)
}
