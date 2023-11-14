//
//  JsonVC.swift
//  palera1nLoader
//
//  Created by samara on 6/6/23.
//

import Foundation
import UIKit

var observation: NSKeyValueObservation?
var progressDownload: UIProgressView = UIProgressView(progressViewStyle: .default)

class JsonVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableData: [[Any]] = [[]]
    var sectionTitles = [""]
    var iconImages: [UIImage?] = []
    var isLoading = true
    var isError = false
    var errorMessage = "Unable to fetch bootstraps."
    var tableView: UITableView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        envInfo.nav = navigationController!
        fetchJSON()
        
        #if !targetEnvironment(simulator)
        switch true {
        case !fileExists("/tmp/palera1n/helper"):
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let alert = UIAlertController.error(title: LocalizationManager.shared.local("NO_PROCEED"), message: LocalizationManager.shared.local("NO_PROCEED_SIDELOADING"))
                self.present(alert, animated: true)
            }
            return

        case envInfo.hasForceReverted:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let alert = UIAlertController.error(title: LocalizationManager.shared.local("NO_PROCEED"), message: LocalizationManager.shared.local("NO_PROCEED_FR"))
                self.present(alert, animated: true)
            }
            return
            
        case (envInfo.CF > 1900):
            if envInfo.isRootful {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    let alertController = whichAlert(title: "Oopsy :3", message: "Rootful on iOS 17+ is not supported. You will get no support, and you're on your own.")
                    let cancelAction = UIAlertAction(title: LocalizationManager.shared.local("CLOSE"), style: .cancel, handler: nil)
                    alertController.addAction(cancelAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                return
            }
            return
        default:
            break
        }
        #endif
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !envInfo.hasChecked {
            Check.prerequisites()
        }
        
        setNavigationBar()
        setTableView()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if isLoading {
                return 1
            } else if isError {
                return 1
            }
            return tableData[section].count
        }
        /* JsonVC has two sections, so if section is not 0, it must be 1. */
        return 2
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            if isLoading {
                return LocalizationManager.shared.local("DOWNLOADING")
            } else if isError {
                return LocalizationManager.shared.local("DOWNLOAD_ERROR")
            }
            return LocalizationManager.shared.local("INSTALL")
        } else {
            /* JsonVC has two sections, so if section is not 0, it must be 1. */
            return LocalizationManager.shared.local("DEBUG")
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: reuseIdentifier)

        cell.isUserInteractionEnabled = true
        cell.selectionStyle = .default
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.textColor = .none
        cell.imageView?.alpha = 1.0
        cell.imageView?.image = nil

        if indexPath.section == 0 {
            if isLoading {
                let loadingCell = tableView.dequeueReusableCell(withIdentifier: LoadingCell.reuseIdentifier, for: indexPath) as! LoadingCell
                loadingCell.isUserInteractionEnabled = false
                loadingCell.startLoading()
                return loadingCell
            } else if isError {
                let errorCell = tableView.dequeueReusableCell(withIdentifier: "ErrorCell", for: indexPath) as! ErrorCell
                errorCell.errorMessage = errorMessage
                errorCell.isUserInteractionEnabled = false
                errorCell.retryAction = { [weak self] in
                    self?.retryFetchJSON()
                }
                return errorCell
            }

            cell.textLabel?.text = tableData[indexPath.section][indexPath.row] as? String
            mods.applyImageModifications(to: cell, with: iconImages[indexPath.row]!)
        } else {
            let row = indexPath.row
            if row == 0 {
                cell.textLabel?.text = LocalizationManager.shared.local("DEBUG_OPTIONS")
                if #available(iOS 13.0, *) { mods.applySymbolModifications(to: cell, with: "hammer.fill", backgroundColor: .systemGray) }
            } else {
                if #available(iOS 13.0, *) { mods.applySymbolModifications(to: cell, with: "trash", backgroundColor: .systemRed) }
                cell.textLabel?.text = LocalizationManager.shared.local("REVERT_CELL")
                if envInfo.isRootful {
                    cell.isUserInteractionEnabled = false
                    cell.textLabel?.textColor = .gray
                    cell.imageView?.alpha = 0.4
                } else {
                    let isProcursusStrapped = FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped")
                    cell.isUserInteractionEnabled = isProcursusStrapped
                    cell.textLabel?.textColor = isProcursusStrapped ? .systemRed : .gray
                    cell.accessoryType = isProcursusStrapped ? .disclosureIndicator : .none
                    cell.imageView?.alpha = isProcursusStrapped ? 1.0 : 0.4
                }
            }
        }

        return cell
    }


    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch (indexPath.section, indexPath.row) {
        case (0, let row):
            let itemTapped = tableData[indexPath.section][indexPath.row]

            guard let name = itemTapped as? String else {
                return
            }

          var filePaths = getCellInfo(envInfo.jsonInfo!)!.paths
            let procursusStrappedExists = FileManager.default.fileExists(atPath: "\(envInfo.installPrefix)/.procursus_strapped")

            let alertController = whichAlert(title: "", message: nil)
            let cancelAction = UIAlertAction(title: LocalizationManager.shared.local("CANCEL"), style: .cancel, handler: nil)
            alertController.addAction(cancelAction)

            if (0..<filePaths.count).contains(row) {
                let filePath = filePaths[row]
                let regex = try! NSRegularExpression(pattern: "\"(.*?)\"")
                let range = NSRange(filePath.startIndex..<filePath.endIndex, in: filePath)
                let matches = regex.matches(in: filePath, range: range)

                for match in matches {
                    if let matchRange = Range(match.range(at: 1), in: filePath) {
                        let filePath = String(filePath[matchRange])
                        filePaths.append(filePath)
                    }
                }

                let components = filePath.components(separatedBy: ",")
                let exists = components.contains { path in
                    let trimmedPath = path.trimmingCharacters(in: .whitespaces)
                    return FileManager.default.fileExists(atPath: trimmedPath)
                }

                let lowercaseName = name.lowercased()

              if procursusStrappedExists {
                  alertController.message = exists ? String(format: NSLocalizedString("DL_STRAP_PM", comment: ""), name, filePath) : String(format: NSLocalizedString("DL_STRAP_NOPM", comment: ""), name)
                  let pkgAction = UIAlertAction(title: exists ? LocalizationManager.shared.local("REINSTALL") : LocalizationManager.shared.local("INSTALL"), style: .default) { _ in
                      self.installDebFile(file: "\(lowercaseName)")
                  }
                  alertController.addAction(pkgAction)
              } else {
                  alertController.message = String(format: NSLocalizedString("DL_NOSTRAP", comment: ""), name)
                  let installAction = UIAlertAction(title: LocalizationManager.shared.local("INSTALL"), style: .default) { _ in
                      self.installStrap(file: name.lowercased()) {}
                  }
                  alertController.addAction(installAction)
              }
            }

            present(alertController, animated: true, completion: nil)
            
        case (1, 0):
          let actionsVC = OptionsVC()

          UIDevice.current.userInterfaceIdiom == .pad ?
          
          showDetailViewController(UINavigationController(rootViewController: actionsVC), sender: nil) :
          navigationController?.pushViewController(actionsVC, animated: true)
        case (1, 1):
            let alertController = whichAlert(title: LocalizationManager.shared.local("CONFIRM"), message: envInfo.rebootAfter ? LocalizationManager.shared.local("REVERT_WARNING") : nil)
            let cancelAction = UIAlertAction(title: LocalizationManager.shared.local("CANCEL"), style: .cancel, handler: nil)
            let confirmAction = UIAlertAction(title: LocalizationManager.shared.local("REVERT_CELL"), style: .destructive) { _ in bootstrap.revert(viewController: self) }
            
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            
            present(alertController, animated: true, completion: nil)
            
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

