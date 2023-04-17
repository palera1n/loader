//
//  ViewController.swift
//  pockiiau
//
//  Created by samiiau on 2/27/23.
//  Copyright © 2023 samiiau. All rights reserved.
//

import UIKit
import CoreServices

var rootful : Bool = false
var inst_prefix: String = "unset"

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var rebootAfter: Bool = true
    var tableData = [[local("SILEO"), local("ZEBRA")], [local("UTIL_CELL"), local("OPEN_CELL"), local("REVERT_CELL")]]
    let sectionTitles = [local("INSTALL"), local("DEBUG")]
    var observation: NSKeyValueObservation?
    var progressDownload: UIProgressView = UIProgressView(progressViewStyle: .default)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (inst_prefix == "unset") { Utils().deviceCheck() }
        let appearance = UINavigationBarAppearance()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        let customView: UIView = {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
            view.translatesAutoresizingMaskIntoConstraints = false

            let button: UIButton = {
                let button = UIButton(type: .custom)
                button.translatesAutoresizingMaskIntoConstraints = false
                button.widthAnchor.constraint(equalToConstant: 25).isActive = true
                button.heightAnchor.constraint(equalToConstant: 25).isActive = true
                button.layer.cornerRadius = 6
                button.clipsToBounds = true
                button.setBackgroundImage(UIImage(named: "AppIcon"), for: .normal)
                button.layer.borderWidth = 0.7
                button.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
                return button
            }()
            view.addSubview(button)
            
            let titleLabel: UILabel = {
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                label.text = "palera1n"
                label.font = UIFont.boldSystemFont(ofSize: 17)
                return label
            }()
            view.addSubview(titleLabel)
            
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                titleLabel.leadingAnchor.constraint(equalTo: button.trailingAnchor, constant: 8),
                titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
            
            return view
        }()

        navigationItem.rightBarButtonItem = Utils.InfoMenu(rootful: rootful)
        navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: customView)]
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
    
    // MARK: - Viewtable for Sileo/Zebra/Revert/Etc
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = tableData[indexPath.section][indexPath.row]
        
        switch tableData[indexPath.section][indexPath.row] {
        case local("REVERT_CELL"):
            if FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                cell.isUserInteractionEnabled = true
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.textColor = .systemRed
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped"){
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textColor = .gray
                cell.detailTextLabel?.text = local("REVERT_SUBTEXT")
            } else {
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textColor = .gray
            }
        case local("SILEO"):
            if let originalImage = UIImage(named: "Sileo_logo") {
                applyImageModifications(to: cell, with: originalImage)
            }
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
        case local("ZEBRA"):
            if let originalImage = UIImage(named: "Zebra_logo") {
                applyImageModifications(to: cell, with: originalImage)
            }
            cell.isUserInteractionEnabled = false
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = .gray
        case local("UTIL_CELL"), local("OPEN_CELL"):
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = UIColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1.0)
        default:
            break
        }
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if let revision = Bundle.main.infoDictionary?["REVISION"] as? String {
            if section == tableData.count - 1 {
                return "universal_lite • 1.0 (\(revision))"
            } else if section == 0 {
                return local("PM_SUBTEXT")
            }
        }
        return nil
    }
    
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let installed = FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped")
        if (indexPath.section == 1 && indexPath.row == 2 && !rootful && installed) {
            return UIContextMenuConfiguration(previewProvider: nil) { [self] _ in
                let doReboot = UIAction(title: "Reboot after revert", image: UIImage(systemName: "power.circle"), state: rebootAfter ? .on : .off ) { _ in
                    if(!self.rebootAfter){self.rebootAfter = true}else{self.rebootAfter = false}
                }
                return UIMenu(title: "", image: nil, identifier: .none, options: .singleSelection, children: [doReboot])
            }
        }
        return nil
    }


    // MARK: - Main table cells
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemTapped = tableData[indexPath.section][indexPath.row]
        switch itemTapped {
        case local("UTIL_CELL"):
            Utils().actionsTapped()
        case local("OPEN_CELL"):
            Utils().openersTapped()
        case local("REVERT_CELL"):
            let alertController = whichAlert(title: local("CONFIRM"), message: local("REVERT_WARNING"))
            let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
            let confirmAction = UIAlertAction(title: local("REVERT_CELL"), style: .destructive) {_ in bootstrap().revert(self.rebootAfter) }
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        case local("SILEO"):
            let sileoInstalled = UIApplication.shared.canOpenURL(URL(string: "sileo://")!)
            if (sileoInstalled) {
                let alertController = whichAlert(title: local("CONFIRM"), message: local("SILEO_REINSTALL"))
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("REINSTALL"), style: .default) { _ in
                    DispatchQueue.global(qos: .default).async {  bootstrap().installDeb("sileo", rootful) }
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                let alertController = whichAlert(title: local("CONFIRM"), message: local("SILEO_INSTALL"))
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("INSTALL"), style: .default) { _ in
                    DispatchQueue.global(qos: .default).async { bootstrap().installDeb("sileo", rootful) }
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else {
                DispatchQueue.global(qos: .userInitiated).async { bootstrap().installStrap("sileo", rootful) }
            }
        case local("ZEBRA"):
            let zebraInstalled = UIApplication.shared.canOpenURL(URL(string: "zbra://")!)
            if (zebraInstalled) {
                let alertController = whichAlert(title: local("CONFIRM"), message: local("ZEBRA_REINSTALL"))
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("REINSTALL"), style: .default) { _ in
                    DispatchQueue.global(qos: .default).async {  bootstrap().installDeb("zebra", rootful) }
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                let alertController = whichAlert(title: local("CONFIRM"), message: local("ZEBRA_INSTALL"))
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("INSTALL"), style: .default) { _ in
                    DispatchQueue.global(qos: .default).async {  bootstrap().installDeb("zebra", rootful) }
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else {
                DispatchQueue.global(qos: .userInitiated).async { bootstrap().installStrap("zebra", rootful) }
            }
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
