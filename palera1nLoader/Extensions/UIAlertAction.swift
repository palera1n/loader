//
//  UIKit.swift
//  loader-rewrite
//
//  Created by samara on 1/30/24.
//

import UIKit

extension UIAlertAction {
    typealias Handler = ((UIAlertAction) -> Void)?
    
    static func customAction(title: String?, style: UIAlertAction.Style, handler: Handler) -> UIAlertAction {
        return UIAlertAction(title: title, style: style, handler: handler)
    }
    
    static func customActionSheet(title: String? = nil, message: String? = nil, actions: [UIAlertAction], sourceView: UIView?, sourceRect: CGRect?) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        
        alertController.addAction(UIAlertAction(title: String.localized("Cancel"), style: .cancel, handler: nil))
        
        for action in actions {
            alertController.addAction(action)
        }
        
        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceRect ?? CGRect.zero
            popoverPresentationController.permittedArrowDirections = .any
        }
        
        return alertController
    }
    
    static func makeActionSheetOrAlert(title: String? = nil, message: String? = nil, actions: [UIAlertAction], sourceView: UIView?, sourceRect: CGRect?) -> UIAlertController {
        return customActionSheet(title: title, message: message, actions: actions, sourceView: sourceView, sourceRect: sourceRect)
    }
}

extension UIAlertController {
    static func error(title: String, message: String, actions: [UIAlertAction]) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: .localized("Exit"), style: .cancel) { _ in
            Go.cleanUp()
            UIApplication.prepareForExitAndSuspend()
        })

        for action in actions {
            alertController.addAction(action)
        }
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        #endif
        return alertController
    }
    
    static func coolAlert(title: String, message: String, actions: [UIAlertAction]) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)

        for action in actions {
            alertController.addAction(action)
        }
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        #endif
        return alertController
    }
    
}

