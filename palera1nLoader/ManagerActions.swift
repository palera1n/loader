//
//  ManagerAlerts.swift
//  loader-rewrite
//
//  Created by samara on 1/30/24.
//

import Foundation
import UIKit

extension ViewController {
    func showAlert(for indexPath: IndexPath, row: Int?, cellData: String? = nil, sourceView: UIView) {
        guard let jsonInfo = jsonInfo else { return }

        var actions: [UIAlertAction] = []
        let filePaths = JailbreakConfiguration.getCellInfo(jsonInfo)!.paths
        let selectedFilePath: String?
        var message: String? = nil
        var exists = false
        
        if let row = row, row < filePaths.count { selectedFilePath = filePaths[row] } else { selectedFilePath = filePaths.first }
        if let filePath = selectedFilePath, FileManager.default.fileExists(atPath: filePath) { exists = true }

        let strapValue = Status.installation()
        switch strapValue {
        case .rootful, .rootless:
            let bootstrapActionTitle = String.localized("Bootstrap Install", arguments: cellData!)                  // Install %@
            let bootstrapAction = UIAlertAction.customAction(title: bootstrapActionTitle, style: .default) { [self] _ in
                
                self.setupContainerView()
                DispatchQueue.main.async {
                    Go.shared.attemptInstall(file: cellData!.lowercased())
                }
            }

            
            actions.append(bootstrapAction)
        case .rootless_installed, .rootful_installed, .simulated:
            message = exists                ? String.localized("Installed Manager", arguments: cellData!)           // %@ is already installed.
                                            : nil
            
            let managerActionTitle = exists ? String.localized("Reinstall Manager", arguments: cellData!)           // Reinstall %@
                                            : String.localized("Bootstrap Install", arguments: cellData!)           // Install %@
            
            let managerAction = UIAlertAction.customAction(title: managerActionTitle, style: .default) { _ in
                
                self.setupContainerView()
                DispatchQueue.main.async {
                    Go.shared.attemptManagerInstall(file: cellData!.lowercased())
                }
            }
            
            actions.append(managerAction)
        }
            
        let alertController = UIAlertAction.makeActionSheetOrAlert(title: nil, message: message, actions: actions)

        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceView.bounds
            popoverPresentationController.permittedArrowDirections = .any
        }

        present(alertController, animated: true, completion: nil)
    }

    
    func showRestoreAlert(sourceView: UIView) {
        var actions: [UIAlertAction] = []

        let message = String.localized("Restore System Explanation", arguments: device)
        
        
        let restoreActionTitle = String.localized("Restore System")
        let restoreAction = UIAlertAction.customAction(title: restoreActionTitle, style: .destructive) { _ in
            Go.restoreSystem()
        }
        actions.append(restoreAction)
            
        let alertController = UIAlertAction.makeActionSheetOrAlert(title: message, message: nil, actions: actions)

        if let popoverPresentationController = alertController.popoverPresentationController {
            popoverPresentationController.sourceView = sourceView
            popoverPresentationController.sourceRect = sourceView.bounds
            popoverPresentationController.permittedArrowDirections = .any
        }
        
        present(alertController, animated: true, completion: nil)
    }
}
