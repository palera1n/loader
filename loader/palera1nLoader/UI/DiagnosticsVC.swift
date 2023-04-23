//
//  DiagnosticsVC.swift
//  palera1nLoader
//
//  Created by samara on 4/22/23.
//

import UIKit

class DiagnosticsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableData = [
        [local("Version"), local("Architecture"), local("TYPE_INFO")],
        
        [local("INSTALL_INFO"), local("STRAP_INFO"), local("STRAP_FR_PREFIX"), local("INSTALL_FR")],
        
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
            let copyAction = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.doc"), identifier: nil, discoverabilityTitle: nil) { action in
                UIPasteboard.general.string = tableView.cellForRow(at: indexPath)?.detailTextLabel?.text ?? ""
            }
            return UIMenu(image: nil, identifier: nil, options: [], children: [copyAction])
        }
    }
    
    func applySymbolModifications(to cell: UITableViewCell, with symbolName: String, backgroundColor: UIColor) {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let symbolImage = UIImage(systemName: symbolName, withConfiguration: symbolConfig)?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        let coloredBackgroundImage = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { context in
            backgroundColor.setFill()
            UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 30, height: 30), cornerRadius: 7).fill()
        }
        let mergedImage = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { context in
            coloredBackgroundImage.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
            symbolImage?.draw(in: CGRect(x: 5, y: 5, width: 20, height: 20)) // adjust the x and y values as needed
        }
        cell.imageView?.image = mergedImage
        cell.imageView?.layer.cornerRadius = 7
        cell.imageView?.clipsToBounds = true
        cell.imageView?.layer.borderWidth = 1
        cell.imageView?.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "Cell"
        let cell = UITableViewCell(style: .value1, reuseIdentifier: reuseIdentifier)
        
        cell.selectionStyle = .none
        
        switch tableData[indexPath.section][indexPath.row] {
        case local("Version"):
            cell.textLabel?.text = local("Version")
            cell.detailTextLabel?.text = UIDevice.current.systemVersion
        case local("Architecture"):
            cell.textLabel?.text = local("Architecture")
            cell.detailTextLabel?.text = envInfo.systemArch
        case local("TYPE_INFO"):
            cell.textLabel?.text = local("TYPE_INFO")
            cell.detailTextLabel?.text = envInfo.isRootful ? local("ROOTFUL") : local("ROOTLESS")
            
            
        case local("INSTALL_INFO"):
            cell.textLabel?.text = local("INSTALL_INFO")
            cell.detailTextLabel?.text = envInfo.isInstalled ? local("TRUE") : local("FALSE")
        case local("STRAP_INFO"):
            cell.textLabel?.text = local("STRAP_INFO")
            cell.detailTextLabel?.text = "\(Int(envInfo.envType))"
        case local("STRAP_FR_PREFIX"):
            cell.textLabel?.text = local("STRAP_FR_PREFIX")
            let jbFolder = Utils().strapCheck().jbFolder
            if !jbFolder.isEmpty {
                let lastPathComponent = URL(fileURLWithPath: jbFolder).lastPathComponent
                cell.detailTextLabel?.text = "\(lastPathComponent)"
            } else {
                cell.detailTextLabel?.text = "None"
            }
        case local("INSTALL_FR"):
            cell.textLabel?.text = local("INSTALL_FR")
            cell.detailTextLabel?.text = envInfo.hasForceReverted ? local("TRUE") : local("FALSE")
            
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

