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
		self.containerView.isHidden = false
		self.tableView.allowsSelection = false
		#if !os(tvOS)
		self.hideStatusBar = true
		#endif
		UIApplication.shared.isIdleTimerDisabled = true
		self.navigationController?.setNavigationBarHidden(true, animated: true)
		UIView.transition(with: self.containerView, duration: 0.5, options: .transitionFlipFromRight, animations: nil, completion: nil)
	}

    
    public func showAlert(row: Int?, title: String? = nil, sourceView: UIView) {

        var actions: [UIAlertAction] = []
		let filePaths = basePath?.managers[row!].filePath
        var message: String? = nil
        var exists = false
        
        if let filePath = filePaths, FileManager.default.fileExists(atPath: filePath) { exists = true }

        let strapValue = Status.installation()
		let meowValue = Status.checkInstallStatus()
		
		switch (strapValue, meowValue) {
		case (.rootless, .none), (.rootful, .none)
			,(.simulated, .none)
			:
			let bootstrapActionTitle = String.localized("Bootstrap Install", arguments: title!)
			let bootstrapAction = UIAlertAction.customAction(title: bootstrapActionTitle, style: .default) { [self] _ in
				DispatchQueue.main.async {
					self.performCommonActions()
					Go.shared.downloadFiles(file: self.basePath?.managers[row!].uri ?? "", basePath: self.basePath)
				}
			}
			
			actions.append(bootstrapAction)
		case (.rootful, .rootful_installed), (.rootless, .rootless_installed)
			//,(.simulated, .rootful_installed)
			:
			message = exists
			? String.localized("Installed Manager", arguments: title!)
			: nil
			
			let managerActionTitle = exists
			? String.localized("Reinstall Manager", arguments: title!)
			: String.localized("Bootstrap Install", arguments: title!)
			
			let managerAction = UIAlertAction.customAction(title: managerActionTitle, style: .default) { _ in
				DispatchQueue.main.async {
					self.performCommonActions()
					Go.shared.attemptManagerInstall(file: self.basePath?.managers[row!].uri ?? "")
				}
			}
			
			actions.append(managerAction)
		case (.rootless, .rootless_partial):
			log(type: .fatal, msg: String.localized("Detected partial rootless installation (missing /var/jb). Please rejailbreak with palera1n and try again"))
			return
		default: break
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

        let message = (paleInfo.palerain_option_ssv && paleInfo.palerain_option_rootful) ? String.localized("Clean FakeFS Explanation", arguments: device) : String.localized("Restore System Explanation", arguments: device)
        let restoreActionTitle = (paleInfo.palerain_option_ssv && paleInfo.palerain_option_rootful) ? String.localized("Clean FakeFS") : String.localized("Restore System")
        let restoreAction = UIAlertAction.customAction(title: restoreActionTitle, style: .destructive) { _ in
            Go.restoreSystem(isCleanFakeFS: (paleInfo.palerain_option_ssv && paleInfo.palerain_option_rootful))
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
