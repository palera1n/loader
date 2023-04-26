//
//  DiagnosticsVC.swift
//  palera1nLoader
//
//  Created by samara on 4/22/23.
//

import UIKit

class DiagnosticsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableData = [
        [local("VERSION_INFO"), local("ARCH_INFO"), local("TYPE_INFO")],
        
        [local("INSTALL_INFO"), local("STRAP_INFO"), local("STRAP_FR_PREFIX"), local("STRAP_FR_PATH"), local("INSTALL_FR")],
        
        [local("HELPER"), local("HELPER_PATH")],
        
        [local("SILEO_INSTALLED"), local("ZEBRA_INSTALLED")]
    ]
    
    let sectionTitles = ["", local("STRAP_INFO"), local("HELPER"), local("INSTALL_INFO")]
    override func viewDidLoad() {
        if (!envInfo.hasChecked) { Utils().prerequisiteChecks() }
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.title = local("DIAGNOSTICS")
        
        let tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions -> UIMenu? in
            let copyAction = UIAction(title: local("COPY"), image: UIImage(systemName: "doc.on.doc"), identifier: nil, discoverabilityTitle: nil) { action in
                UIPasteboard.general.string = tableView.cellForRow(at: indexPath)?.detailTextLabel?.text ?? ""
            }
            
            let title = (tableView.cellForRow(at: indexPath)?.detailTextLabel?.text)!
            let filzaInstalled = UIApplication.shared.canOpenURL(URL(string: "filza://")!)
            let santanderInstalled = UIApplication.shared.canOpenURL(URL(string: "santander://")!)
            var filePath = ""
            var menuOptions = [copyAction]
            
            let openInFilza = UIAction(title: local("OPEN_FILZA"), image: UIImage(systemName: "arrow.uturn.forward"), identifier: nil, discoverabilityTitle: nil) { action in
                UIApplication.shared.open(URL(string: "filza://\(filePath)")!, options: [:], completionHandler: { (success) in })
            }
            
            let openInSantander = UIAction(title: local("OPEN_SANTANDER"), image: UIImage(systemName: "arrow.uturn.forward"), identifier: nil, discoverabilityTitle: nil) { action in
                UIApplication.shared.open(URL(string: "santander://\(filePath)")!, options: [:], completionHandler: { (success) in })
            }
   
            if ((indexPath.section == 1 && indexPath.row == 3) || (indexPath.section == 2 && indexPath.row == 1)) {
                if (filzaInstalled) { menuOptions.append(openInFilza) }
                if (santanderInstalled) { menuOptions.append(openInSantander) }

                filePath = (tableView.cellForRow(at: indexPath)?.detailTextLabel?.text)!
                return UIMenu(title: title, image: nil, identifier: nil, options: [], children: menuOptions)
            } else {
                return UIMenu(image: nil, identifier: nil, options: [], children: [copyAction])
            }
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "Cell"
        let cell = UITableViewCell(style: .value1, reuseIdentifier: reuseIdentifier)
        
        cell.selectionStyle = .none
        
        switch tableData[indexPath.section][indexPath.row] {
        case local("VERSION_INFO"):
            cell.textLabel?.text = local("VERSION_INFO")
            cell.detailTextLabel?.text = UIDevice.current.systemVersion
        case local("ARCH_INFO"):
            cell.textLabel?.text = local("ARCH_INFO")
            cell.detailTextLabel?.text = envInfo.systemArch
        case local("TYPE_INFO"):
            cell.textLabel?.text = local("TYPE_INFO")
            cell.detailTextLabel?.text = envInfo.isRootful ? local("ROOTFUL") : local("ROOTLESS")
            
        case local("INSTALL_INFO"):
            cell.textLabel?.text = local("INSTALL_INFO")
            cell.detailTextLabel?.text = envInfo.isInstalled ? local("TRUE") : local("FALSE")
        case local("INSTALL_FR"):
            cell.textLabel?.text = local("INSTALL_FR")
            cell.detailTextLabel?.text = envInfo.hasForceReverted ? local("TRUE") : local("FALSE")
        case local("STRAP_INFO"):
            cell.textLabel?.text = local("STRAP_INFO")
            cell.detailTextLabel?.text = "\(Int(envInfo.envType))"
        case local("STRAP_FR_PREFIX"):
            cell.textLabel?.text = local("STRAP_FR_PREFIX")
            let jbFolder = Utils().strapCheck().jbFolder
            if !jbFolder.isEmpty {
                cell.detailTextLabel?.text = "\(URL(string: jbFolder)?.lastPathComponent ?? "")"
            } else {
                cell.detailTextLabel?.text = "None"
            }
        case local("STRAP_FR_PATH"):
            cell.textLabel?.text = local("STRAP_FR_PATH")
            let jbFolder = Utils().strapCheck().jbFolder
            if !jbFolder.isEmpty {
                cell.detailTextLabel?.text = "\(jbFolder)/procursus"
            } else {
                cell.detailTextLabel?.text = "None"
            }
            
        case local("HELPER"):
            cell.textLabel?.text = local("HELPER")
            cell.detailTextLabel?.text = envInfo.hasHelper ? local("TRUE") : local("FALSE")
        case local("HELPER_PATH"):
            cell.textLabel?.text = local("HELPER_PATH")
            cell.detailTextLabel?.text = envInfo.helperPath
            
        case local("SILEO_INSTALLED"):
            cell.textLabel?.text = local("SILEO_INSTALLED")
            cell.detailTextLabel?.text = envInfo.sileoInstalled ? local("TRUE") : local("FALSE")
        case local("ZEBRA_INSTALLED"):
            cell.textLabel?.text = local("ZEBRA_INSTALLED")
            cell.detailTextLabel?.text = envInfo.zebraInstalled ? local("TRUE") : local("FALSE")
        default:
            break
        }
        
        return cell
    }



}

