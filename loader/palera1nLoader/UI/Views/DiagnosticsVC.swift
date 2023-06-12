//
//  DiagnosticsVC.swift
//  palera1nLoader
//
//  Created by samara on 4/22/23.
//

import UIKit

class DiagnosticsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableData = [
        [local("VERSION_INFO"), local("ARCH_INFO")],
        
        [local("TYPE_INFO"), local("INSTALL_FR"), local("KINFO_FLAGS"), local("PINFO_FLAGS")],
        
        [local("INSTALL_INFO"), local("STRAP_INFO"), local("STRAP_FR_PREFIX"), local("STRAP_FR_PATH")],
                
        [local("SILEO_INSTALLED"), local("ZEBRA_INSTALLED")]
    ]
    
    let sectionTitles = ["", "PALERA1N", local("STRAP_INFO"), local("INSTALL_INFO")]
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.title = local("DIAGNOSTICS")
        
        let tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        view.addSubview(tableView)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let tableView = view.subviews.first as? UITableView {
            tableView.frame = view.bounds
        }
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
                if let text = tableView.cellForRow(at: indexPath)?.detailTextLabel?.text {
                    UIPasteboard.general.string = text
                }
            }
            
            var menuOptions = [copyAction]
            var filePath = ""
            
            switch (indexPath.section, indexPath.row) {
            case (2, 3) where !envInfo.isRootful:
                let filzaInstalled = UIApplication.shared.canOpenURL(URL(string: "filza://")!)
                let santanderInstalled = UIApplication.shared.canOpenURL(URL(string: "santander://")!)
                
                if filzaInstalled {
                    let openInFilza = UIAction(title: local("OPEN_FILZA"), image: UIImage(systemName: "arrow.uturn.forward"), identifier: nil, discoverabilityTitle: nil) { action in
                        UIApplication.shared.open(URL(string: "filza://\(filePath)")!, options: [:], completionHandler: nil)
                    }
                    menuOptions.append(openInFilza)
                }
                
                if santanderInstalled {
                    let openInSantander = UIAction(title: local("OPEN_SANTANDER"), image: UIImage(systemName: "arrow.uturn.forward"), identifier: nil, discoverabilityTitle: nil) { action in
                        UIApplication.shared.open(URL(string: "santander://\(filePath)")!, options: [:], completionHandler: nil)
                    }
                    menuOptions.append(openInSantander)
                }
                
                if let detailText = tableView.cellForRow(at: indexPath)?.detailTextLabel?.text {
                    filePath = detailText
                    return UIMenu(title: detailText, image: nil, identifier: nil, options: [], children: menuOptions)
                }
                
            case (1, 2), (1, 3):
                let flags = indexPath.row == 2 ? envInfo.kinfoFlagsStr : envInfo.pinfoFlagsStr
                return UIMenu(title: flags, image: nil, identifier: nil, options: [], children: [copyAction])
                
            case (0, 0):
                let model = UIDevice.current.model
                let kernel = UIDevice.current.systemVersion
                let infoTitle = "\(local("DEVICE_MODEL")) \(model)\n\(local("DEVICE_MODEL_KERN")) \(kernel)\n\(local("DEVICE_MODEL_CF")) \(floor(kCFCoreFoundationVersionNumber))"
                return UIMenu(title: infoTitle, image: nil, identifier: nil, options: [], children: [copyAction])
                
            default:
                return UIMenu(image: nil, identifier: nil, options: [], children: [copyAction])
            }
            
            return nil
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
            let jbFolder = Check.installation().jb_folder
            if (jbFolder != nil) {
                cell.detailTextLabel?.text = "\(URL(string: jbFolder!)?.lastPathComponent ?? "")"
            } else {
                cell.detailTextLabel?.text = local("NONE")
            }
        case local("STRAP_FR_PATH"):
            cell.textLabel?.text = local("STRAP_FR_PATH")
            if !envInfo.isRootful {
                if (envInfo.jbFolder == "") {
                    cell.detailTextLabel?.text = local("NONE")
                } else {
                    cell.detailTextLabel?.text = "\(envInfo.jbFolder)/procursus"
                }
            } else {
                cell.detailTextLabel?.text = local("NONE")
            }
        case local("KINFO_FLAGS"):
            cell.textLabel?.text = local("KINFO_FLAGS")
            cell.detailTextLabel?.text = envInfo.kinfoFlags
        case local("PINFO_FLAGS"):
            cell.textLabel?.text = local("PINFO_FLAGS")
            cell.detailTextLabel?.text = envInfo.pinfoFlags
            
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
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case tableData.count - 1:
            return """
            © 2023, palera1n team
            
            \(local("CREDITS_SUBTEXT"))
            @flowerible (Samara) & @staturnzdev (Staturnz)
            """
        case 1:
            return """
            \(local("PINFO_SUBTEXT"))
            """
        default:
            return nil
        }
    }
}

