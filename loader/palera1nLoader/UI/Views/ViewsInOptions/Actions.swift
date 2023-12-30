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
        [LocalizationManager.shared.local("ACTION_HIDEJB")],
        [LocalizationManager.shared.local("ACTION_RESPRING"), LocalizationManager.shared.local("ACTION_UICACHE")],
        [LocalizationManager.shared.local("OPENER_SILEO"), LocalizationManager.shared.local("OPENER_ZEBRA")],
        [LocalizationManager.shared.local("ACTION_USREBOOT")]
    ]
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        envInfo.nav = navigationController!
    }
  
    var sectionTitles = ["", "", "", ""]
    override func viewDidLoad() {
        super.viewDidLoad()
        let tableView: UITableView
        if #available(iOS 13.0, *) {
            self.view.backgroundColor = UIColor.systemBackground
            let appearance = UINavigationBarAppearance()
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            tableView = UITableView(frame: view.bounds, style: isIpad == .pad ? .insetGrouped : .grouped)
        } else {
            tableView = UITableView(frame: view.bounds, style: .grouped)
        }
        
        self.title = LocalizationManager.shared.local("ACTIONS")

        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "Cell"
        let cell = UITableViewCell(style: .value1, reuseIdentifier: reuseIdentifier)
        cell.accessoryType = .none
        cell.selectionStyle = .default
        
        switch tableData[indexPath.section][indexPath.row] {
        case LocalizationManager.shared.local("ACTION_HIDEJB"):
            if #available(iOS 13.0, *) { mods.applySymbolModifications(to: cell, with: "eye.slash.circle", backgroundColor: .purple) }
            cell.textLabel?.text = LocalizationManager.shared.local("ACTION_HIDEJB")
            cell.accessoryType = .disclosureIndicator
        case LocalizationManager.shared.local("OPENER_SILEO"):
            cell.textLabel?.textColor = .systemBlue
            cell.textLabel?.text = LocalizationManager.shared.local("OPENER_SILEO")
        case LocalizationManager.shared.local("OPENER_ZEBRA"):
            cell.textLabel?.textColor = .systemBlue
            cell.textLabel?.text = LocalizationManager.shared.local("OPENER_ZEBRA")
            
        case LocalizationManager.shared.local("ACTION_RESPRING"):
            cell.textLabel?.text = LocalizationManager.shared.local("ACTION_RESPRING")
            cell.textLabel?.textColor = .systemBlue
        case LocalizationManager.shared.local("ACTION_UICACHE"):
            cell.textLabel?.textColor = .systemBlue
            cell.textLabel?.text = LocalizationManager.shared.local("ACTION_UICACHE")
    
        case LocalizationManager.shared.local("ACTION_USREBOOT"):
            cell.textLabel?.text = LocalizationManager.shared.local("ACTION_USREBOOT")
            cell.textLabel?.textColor = .systemOrange
            cell.textLabel?.textColor = .systemOrange
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemTapped = tableData[indexPath.section][indexPath.row]
        switch itemTapped {
        case LocalizationManager.shared.local("ACTION_HIDEJB"):
            HideEnv(viewController: self)
        case LocalizationManager.shared.local("OPENER_SILEO"):
            if opener.openApp("org.coolstar.SileoStore") {} else if opener.openApp("org.coolstar.SileoNightly") {}
        case LocalizationManager.shared.local("OPENER_ZEBRA"):
            if opener.openApp("xyz.willy.Zebra") {}
        case LocalizationManager.shared.local("ACTION_RESPRING"):
            spawn(command: "/cores/binpack/bin/launchctl", args: ["kickstart", "-k", "system/com.apple.backboardd"])
        case LocalizationManager.shared.local("ACTION_UICACHE"):
            spawn(command: "\(envInfo.installPrefix)/usr/bin/uicache", args: ["-a"])
        case LocalizationManager.shared.local("ACTION_USREBOOT"):
            spawn(command: "/cores/binpack/bin/launchctl", args: ["reboot", "userspace"])
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let dataCount = tableData.count
        if section == dataCount - 2 {
            return LocalizationManager.shared.local("OPENER_SUBTEXT")
        }
        return nil
    }
    
    private func HideEnv(viewController: UIViewController) {
            if (paleInfo.palerain_option_rootless) {
                let strapValue = Check.installation()
                switch strapValue {
                case .rootless_installed:
                    #if !targetEnvironment(simulator)
                    let alert = UIAlertController.warning(title: LocalizationManager.shared.local("ACTION_HIDEJB"), message: LocalizationManager.shared.local("HIDE_NOTICE"), destructiveBtnTitle: LocalizationManager.shared.local("PROCEED"), destructiveHandler: {
                        if fileExists("/var/jb") {
                            binpack.rm("/var/jb")
                        }
                        spawn(command: "/cores/binpack/bin/launchctl", args: ["reboot"])
                    })
                    viewController.present(alert, animated: true)
                    #endif
                default:
                    let errorAlert = UIAlertController.error(title: LocalizationManager.shared.local("NO_PROCEED"), message: "\(LocalizationManager.shared.local("STRAP_INFO")) \(strapValue)")
                    viewController.present(errorAlert, animated: true)
                }
            } else {
                let errorAlert = UIAlertController.error(title: LocalizationManager.shared.local("NO_PROCEED"), message: LocalizationManager.shared.local("NOTICE_ROOTLESS"))
                viewController.present(errorAlert, animated: true)
                return
            }
        }
}
