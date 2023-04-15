//
//  ViewController.swift
//  pockiiau
//
//  Created by samiiau on 2/27/23.
//  Copyright © 2023 samiiau. All rights reserved.
//

import UIKit
import LaunchServicesBridge
import CoreServices
import MachO

var rootful : Bool = false
var inst_prefix: String = "unset"

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var rebootAfter: Bool = true
    var tableData = [[local("SILEO"), local("ZEBRA")], [local("UTIL_CELL"), local("OPEN_CELL"), local("REVERT_CELL")]]
    let sectionTitles = [local("INSTALL"), local("DEBUG")]

    override func viewDidLoad() {
        super.viewDidLoad()
        if (inst_prefix == "unset") { deviceCheck()}
        
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
                button.layer.borderWidth = 0.5
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

        let discord = UIAction(title: local("DISCORD"), image: UIImage(systemName: "arrow.up.forward.app")) { (_) in
            UIApplication.shared.open(URL(string: "https://discord.gg/palera1n")!)
        }
        let twitter = UIAction(title: local("TWITTER"), image: UIImage(systemName: "arrow.up.forward.app")) { (_) in
            UIApplication.shared.open(URL(string: "https://twitter.com/palera1n")!)
        }
        let website = UIAction(title: local("WEBSITE"), image: UIImage(systemName: "arrow.up.forward.app")) { (_) in
            UIApplication.shared.open(URL(string: "https://palera.in")!)
        }

        var type = "Unknown"
        if rootful { type = local("ROOTFUL") }
        else if !rootful { type = local("ROOTLESS") }
        var installed = local("FALSE")
        if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {installed = local("TRUE")}
        let processInfo = ProcessInfo()
        let operatingSystemVersion = processInfo.operatingSystemVersion
        let systemVersion = "\(local("VERSION_INFO")) \(operatingSystemVersion.majorVersion).\(operatingSystemVersion.minorVersion).\(operatingSystemVersion.patchVersion)"
        let arch = String(cString: NXGetLocalArchInfo().pointee.name)
        let menu = UIMenu(title: "\(local("TYPE_INFO")) \(type)\n\(local("INSTALL_INFO")) \(installed)\n\(local("ARCH_INFO")) \(arch)\n\(systemVersion)", children: [discord, twitter, website])
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "info.circle"), primaryAction: nil, menu: menu)
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
    
    
    // MARK: - Viewtable for Sileo/Zebra/Revert/Etc
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.imageView?.layer.cornerRadius = 6
        cell.imageView?.clipsToBounds = true
        cell.imageView?.layer.borderWidth = 0.5
        cell.imageView?.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        cell.textLabel?.text = tableData[indexPath.section][indexPath.row]

        switch tableData[indexPath.section][indexPath.row] {
        case local("REVERT_CELL"):
            if FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                cell.isHidden = false
                cell.isUserInteractionEnabled = true
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.textColor = UIColor(red: 0.90, green: 0.29, blue: 0.29, alpha: 1.00)
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped"){
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textColor = .gray
                cell.detailTextLabel?.text = local("REVERT_SUBTEXT")
                cell.selectionStyle = .none
            } else {
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textColor = .gray
                cell.selectionStyle = .none
            }
        case local("SILEO"):
            let originalImage = UIImage(named: "Sileo_logo")
            let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { _ in
                originalImage?.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
            }
            cell.imageView?.image = resizedImage
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        case local("ZEBRA"):
            let originalImage = UIImage(named: "Zebra_logo")
            let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { _ in
                originalImage?.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
            }
            cell.imageView?.image = resizedImage
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        case local("UTIL_CELL"), local("OPEN_CELL"):
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = UIColor(red: 0.89, green: 0.52, blue: 0.43, alpha: 1.00)
            cell.selectionStyle = .default
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


    // MARK: - Actions 'open app' + 'utilities' for alertController
    @objc func openersTapped() {
        let alertController = whichAlert(title: local("OPENER_MSG"))
        let actions: [(title: String, imageName: String, handler: () -> Void)] = [
            (title: local("OPENER_SILEO"), imageName: "arrow.up.forward.app", handler: {
                if (openApp("org.coolstar.SileoStore")){}else{_ = openApp("org.coolstar.SileoNightly")}
            }),
            (title: local("OPENER_ZEBRA"), imageName: "arrow.up.forward.app", handler: { _ = openApp("xyz.willy.Zebra")}),
            (title: local("OPENER_TH"), imageName: "arrow.up.forward.app", handler: { _ = openApp("com.opa334.trollstorepersistencehelper")})
        ]
        
        for action in actions {
            let alertAction = UIAlertAction(title: action.title, style: .default) { (_) in action.handler() }
            alertAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            if let image = UIImage(systemName: action.imageName) { alertAction.setValue(image, forKey: "image") }
            alertController.addAction(alertAction)
        }
        
        alertController.addAction(UIAlertAction(title: local("CANCEL"), style: .cancel) { (_) in})
        present(alertController, animated: true, completion: nil)
    }
    
    
    @objc func actionsTapped() {
        var pre = "/var/jb"
        if rootful { pre = "/"}
        let alertController = whichAlert(title: local("UTIL_CELL"))

        let actions: [(title: String, imageName: String, handler: () -> Void)] = [
            (title: local("RESPRING"), imageName: "arrow.clockwise.circle", handler: { spawn(command: "\(pre)/usr/bin/sbreload", args: [], root: true)}),
            (title: local("US_REBOOT"), imageName: "power.circle", handler: { spawn(command: "\(pre)/usr/bin/launchctl", args: ["reboot", "userspace"], root: true)}),
            (title: local("UICACHE"), imageName: "xmark.circle", handler: { spawn(command: "\(pre)/usr/bin/uicache", args: ["-a"], root: true)}),
            (title: local("DAEMONS"), imageName: "play.circle", handler: { spawn(command: "\(pre)/bin/launchctl", args: ["bootstrap", "system", "/var/jb/Library/LaunchDaemons"], root: true)}),
            (title: local("MOUNT"), imageName: "folder.circle", handler: { spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true); spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true) }),
            (title: local("TWEAKS"), imageName: "iphone.circle", handler: {
                if rootful {spawn(command: "/etc/rc.d/substitute-launcher", args: [], root: true)}
                else {spawn(command: "/var/jb/usr/libexec/ellekit/loader", args: [], root: true)}
            })
        ]

        for action in actions {
            let alertAction = UIAlertAction(title: action.title, style: .default) { (_) in action.handler() }
            alertAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            if let image = UIImage(systemName: action.imageName) { alertAction.setValue(image, forKey: "image") }
            alertController.addAction(alertAction)
        }

        alertController.addAction(UIAlertAction(title: local("CANCEL"), style: .cancel) { (_) in})
        present(alertController, animated: true, completion: nil)
    }

    
    // MARK: - Main table cells
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemTapped = tableData[indexPath.section][indexPath.row]
        switch itemTapped {
        case local("UTIL_CELL"):
            actionsTapped()
        case local("OPEN_CELL"):
            openersTapped()
        case local("REVERT_CELL"):
            let alertController = whichAlert(title: local("CONFIRM"), message: local("REVERT_WARNING"))
            let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
            let confirmAction = UIAlertAction(title: local("REVERT_CELL"), style: .destructive) {_ in revert(self.rebootAfter) }
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        case local("SILEO"):
            let sileoInstalled = UIApplication.shared.canOpenURL(URL(string: "sileo://")!)
            if (sileoInstalled) {
                let alertController = whichAlert(title: local("CONFIRM"), message: local("SILEO_REINSTALL"))
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("REINSTALL"), style: .default) { _ in
                    DispatchQueue.global(qos: .default).async { installDeb("sileo", rootful) }
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                let alertController = whichAlert(title: local("CONFIRM"), message: local("SILEO_INSTALL"))
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("INSTALL"), style: .default) { _ in
                    DispatchQueue.global(qos: .default).async { installDeb("sileo", rootful) }
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else {
                DispatchQueue.global(qos: .userInitiated).async {
                    print("[strap] User initiated strap process...")
                    combo("sileo", false)
                }
            }
        case local("ZEBRA"):
            let zebraInstalled = UIApplication.shared.canOpenURL(URL(string: "zbra://")!)
            if (zebraInstalled) {
                let alertController = whichAlert(title: local("CONFIRM"), message: local("ZEBRA_REINSTALL"))
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("REINSTALL"), style: .default) { _ in
                    DispatchQueue.global(qos: .default).async { installDeb("zebra", rootful) }
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                let alertController = whichAlert(title: local("CONFIRM"), message: local("ZEBRA_INSTALL"))
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("INSTALL"), style: .default) { _ in
                    DispatchQueue.global(qos: .default).async { installDeb("zebra", rootful) }
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else {
                DispatchQueue.global(qos: .userInitiated).async {
                    print("[strap] User initiated strap process...")
                    combo("zebra", rootful)
                }
            }
            
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
