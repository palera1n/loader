//
//  Common.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/10/23.
//

import Foundation
import Extras
import UIKit

//MARK: - Main information struct

struct envInfo {
    static var isRootful: Bool = false
    static var isSimulator: Bool = false
    static var installPrefix: String = "unset"
    static var rebootAfter: Bool = true
    static var envType: Int = -1
    static var systemVersion: String = "unset"
    static var systemArch: String = "unset"
    static var isInstalled: Bool = false
    static var hasForceReverted: Bool = false
    static var sileoInstalled: Bool = false
    static var zebraInstalled: Bool = false
    static var hasChecked: Bool = false
    static var kinfoFlags: String = ""
    static var pinfoFlags: String = ""
    static var kinfoFlagsStr: String = ""
    static var pinfoFlagsStr: String = ""
    static var jbFolder: String = ""
    static var CF = Int(floor(kCFCoreFoundationVersionNumber / 100) * 100)
    static var bmHash: String = ""
    static var nav: UINavigationController = UINavigationController()
}

//MARK: - Commonly used Functions

// String Localization
func local(_ str: String.LocalizationValue) -> String {
    return String(localized: str)
}

// iPad/iPhone Alert Type
func whichAlert(title: String, message: String? = nil) -> UIAlertController {
    if UIDevice.current.userInterfaceIdiom == .pad {
        return UIAlertController(title: title, message: message, preferredStyle: .alert)
    }
    return UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
}

func fileExists(_ path: String) -> Bool {
    return FileManager.default.fileExists(atPath: path)
}

@discardableResult func openApp(_ bundle: String) -> Bool {
    return LSApplicationWorkspace.default().openApplication(withBundleID: bundle)
}

// Execute palera1n helper
@discardableResult func helper(args: [String]) -> Int {
   return spawn(command: "/var/mobile/Library/palera1n/helper", args: args, root: true)
}

// Execute binpack ln
@discardableResult func bp_ln(_ src: String,_ dest: String) -> Int {
    return spawn(command: "/cores/binpack/bin/ln", args: ["-s", src, dest], root: true)
}

// Execute binpack rm
@discardableResult func bp_rm(_ file: String) -> Int {
    return spawn(command: "/cores/binpack/bin/rm", args: ["-rf", file], root: true)
}


//MARK: - Image Modification for Cells

func applySymbolModifications(to cell: UITableViewCell, with symbolName: String, backgroundColor: UIColor) {
    let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
    let symbolImage = UIImage(systemName: symbolName, withConfiguration: symbolConfig)?
        .withTintColor(.white, renderingMode: .alwaysOriginal)
    let symbolSize = symbolImage?.size ?? .zero
    let imageSize = CGSize(width: 30, height: 30)
    let scale = min((imageSize.width - 6) / symbolSize.width, (imageSize.height - 6) / symbolSize.height)
    let adjustedSymbolSize = CGSize(width: symbolSize.width * scale, height: symbolSize.height * scale)
    let coloredBackgroundImage = UIGraphicsImageRenderer(size: imageSize).image { context in
        backgroundColor.setFill()
        UIBezierPath(roundedRect: CGRect(origin: .zero, size: imageSize), cornerRadius: 7).fill()
    }
    let mergedImage = UIGraphicsImageRenderer(size: imageSize).image { context in
        coloredBackgroundImage.draw(in: CGRect(origin: .zero, size: imageSize))
        symbolImage?.draw(in: CGRect(x: (imageSize.width - adjustedSymbolSize.width) / 2, y: (imageSize.height - adjustedSymbolSize.height) / 2, width: adjustedSymbolSize.width, height: adjustedSymbolSize.height))
    }
    cell.imageView?.image = mergedImage
    cell.imageView?.layer.cornerRadius = 7
    cell.imageView?.clipsToBounds = true
    cell.imageView?.layer.borderWidth = 1
    cell.imageView?.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
}

func applyImageModifications(to cell: UITableViewCell, with originalImage: UIImage) {
    let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { context in
        originalImage.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
    }
    cell.imageView?.image = resizedImage
    cell.imageView?.layer.cornerRadius = 7
    cell.imageView?.clipsToBounds = true
    cell.imageView?.layer.borderWidth = 1
    cell.imageView?.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
}

//MARK: - Extension for resused UIAlertControllers

extension UIAlertController {
    
    // Warning Alert
    static func warning(title: String, message: String, destructiveBtnTitle: String?, destructiveHandler: (() -> Void)?) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let destructiveTitle = destructiveBtnTitle, let handler = destructiveHandler {
            alertController.addAction(UIAlertAction(title: destructiveTitle, style: .destructive) { _ in handler() })
        }
        alertController.addAction(UIAlertAction(title: local("CANCEL"), style: .cancel) { _ in return })
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        return alertController
    }
    
    // Error Alert
    static func error(title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: local("CLOSE"), style: .default) { _ in
            bootstrap().cleanUp()
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { exit(0) }
        })
        alertController.addAction(UIAlertAction(title: local("LOG_CELL_VIEW"), style: .default, handler: { (_) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                log(type: .info, msg: "Opening Log View")
                let LogViewVC = LogViewer()
                let navController = UINavigationController(rootViewController: LogViewVC)
                let closeButton = UIBarButtonItem(title: local("CLOSE"), style: .done, target: self, action: #selector(self.closeapp(_:)))
                LogViewVC.navigationItem.leftBarButtonItem = closeButton
                navController.modalPresentationStyle = .formSheet
                envInfo.nav.present(navController, animated: true, completion: nil)
            }
        }))
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        return alertController
    }

    @objc func closeapp(_ sender:UIBarButtonItem!) {
        bootstrap().cleanUp()
        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { exit(0) }
    }

    // Downloading Alert
    static func downloading(_ msg: String.LocalizationValue) -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: local(msg), preferredStyle: .alert)
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
    static func spinnerAlert(_ msg: String.LocalizationValue) -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: local(msg), preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        alertController.view.addSubview(loadingIndicator)
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()
        return alertController
    }
}
