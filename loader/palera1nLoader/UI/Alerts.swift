//
//  Alerts.swift
//  palera1nLoader
//
//  Created by Staturnz on 6/11/23.
//

import Foundation
import UIKit

public func whichAlert(title: String, message: String? = nil) -> UIAlertController {
    if UIDevice.current.userInterfaceIdiom == .pad {
        return UIAlertController(title: title, message: message, preferredStyle: .alert)
    }
    return UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
}

extension UIAlertController {
    // Warning Alert
    static func warning(title: String, message: String, destructiveBtnTitle: String?, destructiveHandler: (() -> Void)?) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let destructiveTitle = destructiveBtnTitle, let handler = destructiveHandler {
            alertController.addAction(UIAlertAction(title: destructiveTitle, style: .destructive) { _ in handler() })
        }
        alertController.addAction(UIAlertAction(title: LocalizationManager.shared.local("CANCEL"), style: .cancel) { _ in return })
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        return alertController
    }
    
    // Error Alert
    static func error(title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: LocalizationManager.shared.local("CLOSE"), style: .default) { _ in
            bootstrap.cleanUp()
          UIApplication.shared.openSpringBoard()
          exit(0)
        })
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        return alertController
    }

    // Downloading Alert
    static func downloading(_ msg: String) -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: LocalizationManager.shared.local(msg), preferredStyle: .alert)
        let constraintHeight = NSLayoutConstraint(item: alertController.view!, attribute: NSLayoutConstraint.Attribute.height,
                                                  relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute:
                                                    NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 75)
        alertController.view.addConstraint(constraintHeight)
        progressDownload.setProgress(0.0/1.0, animated: true)
        progressDownload.frame = CGRect(x: 25, y: 55, width: 220, height: 0)
        alertController.view.addSubview(progressDownload)
        return alertController
    }
    
    // Spinner/Installing Alert
    static func spinnerAlert(_ msg: String) -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: LocalizationManager.shared.local(msg), preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        alertController.view.addSubview(loadingIndicator)
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()
        return alertController
    }
}
