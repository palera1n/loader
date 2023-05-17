//
//  ActionsVC.swift
//  palera1nLoader
//
//  Created by samara on 4/22/23.
//

import Foundation
import UIKit

class ActionsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableData = [
        [local("ACTION_RESPRING"), local("ACTION_UICACHE"), local("ACTION_TWEAKS")],
        [local("OPENER_SILEO"), local("OPENER_ZEBRA"), local("OPENER_TH")],
        [local("ACTION_USREBOOT"), local("ACTION_DAEMONS"), local("ACTION_MOUNT")]
    ]
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        envInfo.nav = navigationController!
    }
  
    var sectionTitles = ["", "", ""]
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.title = local("ACTIONS")
        
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(title: "Settings", style: .plain, target: self, action: #selector(closeSheet))

        let tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        //view
        view.backgroundColor = UIColor.systemGray6
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInset = UIEdgeInsets(top: -25, left: 0, bottom: 40, right: 0)
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    @objc func closeSheet() {
        log(type: .info, msg: "Opening Log View")
        let LogViewVC = DebugVC()
        navigationController?.pushViewController(LogViewVC, animated: true)
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "Cell"
        let cell = UITableViewCell(style: .value1, reuseIdentifier: reuseIdentifier)
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        
        switch tableData[indexPath.section][indexPath.row] {
        case local("OPENER_SILEO"):
            applySymbolModifications(to: cell, with: "arrow.uturn.forward", backgroundColor: .systemGray)
            cell.textLabel?.text = local("OPENER_SILEO")
        case local("OPENER_ZEBRA"):
            applySymbolModifications(to: cell, with: "arrow.uturn.forward", backgroundColor: .systemGray)
            cell.textLabel?.text = local("OPENER_ZEBRA")
        case local("OPENER_TH"):
            applySymbolModifications(to: cell, with: "arrow.uturn.forward", backgroundColor: .systemGray)
            cell.textLabel?.text = local("OPENER_TH")
            
        case local("ACTION_RESPRING"):
            applySymbolModifications(to: cell, with: "arrow.counterclockwise.circle", backgroundColor: .systemBlue)
            cell.textLabel?.text = local("ACTION_RESPRING")
        case local("ACTION_UICACHE"):
            applySymbolModifications(to: cell, with: "iphone.circle", backgroundColor: .systemPurple)
            cell.textLabel?.text = local("ACTION_UICACHE")
        case local("ACTION_TWEAKS"):
            applySymbolModifications(to: cell, with: "hammer.circle", backgroundColor: .systemPink)
            cell.textLabel?.text = local("ACTION_TWEAKS")
            
        case local("ACTION_USREBOOT"):
            applySymbolModifications(to: cell, with: "bolt.circle", backgroundColor: .systemOrange)
            cell.textLabel?.text = local("ACTION_USREBOOT")
            cell.textLabel?.textColor = .systemOrange
        case local("ACTION_DAEMONS"):
            applySymbolModifications(to: cell, with: "eject.circle", backgroundColor: .systemOrange)
            cell.textLabel?.text = local("ACTION_DAEMONS")
            cell.textLabel?.textColor = .systemOrange
        case local("ACTION_MOUNT"):
            applySymbolModifications(to: cell, with: "tray.circle", backgroundColor: .systemOrange)
            cell.textLabel?.text = local("ACTION_MOUNT")
            cell.textLabel?.textColor = .systemOrange
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let prefix = envInfo.installPrefix
        let itemTapped = tableData[indexPath.section][indexPath.row]
        switch itemTapped {
        case local("OPENER_SILEO"):
            if openApp("org.coolstar.SileoStore") {
            } else if openApp("org.coolstar.SileoNightly") {
            } else {
                log(type: .info, msg: "Cannot open Sileo app")
            }
        case local("OPENER_ZEBRA"):
            if !openApp("xyz.willy.Zebra") {
                log(type: .info, msg: "Cannot open Zebra app")
            }
        case local("OPENER_TH"):
            openTrollHelper()
        case local("ACTION_RESPRING"):
            spawn(command: "/cores/binpack/bin/launchctl", args: ["kickstart", "-k", "system/com.apple.backboardd"], root: true)
        case local("ACTION_UICACHE"):
            spawn(command: "\(prefix)/usr/bin/uicache", args: ["-a"], root: true)
        case local("ACTION_TWEAKS"):
            if envInfo.isRootful {
                spawn(command: "/etc/rc.d/substitute-launcher", args: [], root: true)
                spawn(command: "/etc/rc.d/ellekit-loader", args: [], root: true)
            } else {
                spawn(command: "/var/jb/usr/libexec/ellekit/loader", args: [], root: true)
            }
            
        case local("ACTION_USREBOOT"):
            spawn(command: "/cores/binpack/bin/launchctl", args: ["reboot", "userspace"], root: true)
        case local("ACTION_DAEMONS"):
            if envInfo.isRootful {
                spawn(command: "/cores/binpack/bin/launchctl", args: ["bootstrap", "system", "/Library/LaunchDaemons"], root: true)
            } else {
                spawn(command: "/cores/binpack/bin/launchctl", args: ["bootstrap", "system", "/var/jb/Library/LaunchDaemons"], root: true)
            }
        case local("ACTION_MOUNT"):
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
            spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case tableData.count - 3:
            return "When using palera1n on an iPad, theres cases where you would need to use these actions to open the installed applications as they don't appear on the homescreen."
        default:
            return nil
        }
    }
}
