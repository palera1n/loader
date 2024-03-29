//
//  ManagerAlerts.swift
//  loader-rewrite
//
//  Created by samara on 1/30/24.
//

import Foundation
import UIKit

extension ViewController {
    
    fileprivate func performCommonActions() {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.setupContainerView()
        #if !os(tvOS)
        self.hideStatusBar = true
        #endif
    }
    
    public func showAlert(for indexPath: IndexPath, row: Int?, cellData: String? = nil, sourceView: UIView) {
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
        case .rootful, .rootless, .simulated:
            let bootstrapActionTitle = String.localized("Bootstrap Install", arguments: cellData!)
            let bootstrapAction = UIAlertAction.customAction(title: bootstrapActionTitle, style: .default) { [self] _ in
                DispatchQueue.main.async {
                    self.performCommonActions()
                    Go.shared.attemptInstall(file: cellData!.lowercased())
                }
            }

            actions.append(bootstrapAction)
        case .rootless_installed, .rootful_installed:
            message = exists
            ? String.localized("Installed Manager", arguments: cellData!)
            : nil
            
            let managerActionTitle = exists 
            ? String.localized("Reinstall Manager", arguments: cellData!)
            : String.localized("Bootstrap Install", arguments: cellData!)
            
            let managerAction = UIAlertAction.customAction(title: managerActionTitle, style: .default) { _ in
                DispatchQueue.main.async {
                    self.performCommonActions()
                    Go.shared.attemptManagerInstall(file: cellData!.lowercased())
                }
            }
            
            actions.append(managerAction)
        }
            
        let alertController = UIAlertAction.makeActionSheetOrAlert(
            title: nil,
            message: message,
            actions: actions,
            sourceView: sourceView,
            sourceRect: sourceView.bounds
        )

        present(alertController, animated: true, completion: nil)
    }
    
    public func showRestoreAlert(sourceView: UIView) {
        var actions: [UIAlertAction] = []

        let message = String.localized("Restore System Explanation", arguments: device)
        let restoreActionTitle = String.localized("Restore System")
        let restoreAction = UIAlertAction.customAction(title: restoreActionTitle, style: .destructive) { _ in
            Go.restoreSystem()
        }
        actions.append(restoreAction)
            
        let alertController = UIAlertAction.makeActionSheetOrAlert(
            title: nil,
            message: message,
            actions: actions,
            sourceView: sourceView,
            sourceRect: sourceView.bounds
        )
        
        present(alertController, animated: true, completion: nil)
    }
}
