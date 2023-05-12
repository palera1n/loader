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
        [local("FR_SWITCH"), local("ACTION_HIDEJB")],
        
        [local("OPENER_SILEO"), local("OPENER_ZEBRA"), local("OPENER_TH")],
        
        [local("ACTION_RESPRING"), local("ACTION_UICACHE"), local("ACTION_TWEAKS")],
        
        [local("ACTION_USREBOOT"), local("ACTION_DAEMONS"), local("ACTION_MOUNT")]
    ]
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        envInfo.nav = navigationController!
    }
  
    var sectionTitles = ["", "OPENERS", "UTILITIES", ""]
    override func viewDidLoad() {
        if (envInfo.isRootful) {
            tableData = [
                [local("OPENER_SILEO"), local("OPENER_ZEBRA"), local("OPENER_TH")],
                
                [local("ACTION_RESPRING"), local("ACTION_UICACHE"), local("ACTION_TWEAKS")],
                
                [local("ACTION_USREBOOT"), local("ACTION_DAEMONS"), local("ACTION_MOUNT")]
            ]
            sectionTitles = ["OPENERS", "UTILITIES", ""]
        }
        
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.title = local("ACTIONS")
        
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "Cell"
        let cell = UITableViewCell(style: .value1, reuseIdentifier: reuseIdentifier)
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        
        switch tableData[indexPath.section][indexPath.row] {
        case local("FR_SWITCH"):
            applySymbolModifications(to: cell, with: "arrow.forward.circle", backgroundColor: .systemPurple)
            let switchControl = UISwitch()
            switchControl.isOn = envInfo.rebootAfter
            switchControl.addTarget(self, action: #selector(switchToggled(_:)), for: .valueChanged)
            cell.accessoryView = switchControl
            cell.textLabel?.text = local("FR_SWITCH")
            cell.selectionStyle = .none
        case local("ACTION_HIDEJB"):
            applySymbolModifications(to: cell, with: "eye.slash.circle", backgroundColor: .systemIndigo)
            cell.textLabel?.text = local("ACTION_HIDEJB")
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
        case local("ACTION_HIDEJB"):
            HideEnv(viewController: self)
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
        case tableData.count - 1:
            return "\"Mount Directories\" only attempts to mount root and preboot as read/write."
        case tableData.count - 2:
            return "Common utilities for palera1n, \"Enable Tweaks\" only tries to attempt to enable ElleKit or Substitute."
        case tableData.count - 3:
            return "When using palera1n on an iPad, theres cases where you would need to use these actions to open the installed applications as they don't appear on the homescreen."
        default:
            return nil
        }
    }
    
    private func HideEnv(viewController: UIViewController) {
        if (!envInfo.isRootful) {
            let strapValue = envInfo.envType
            switch strapValue {
            case 1:
                let alert = UIAlertController.warning(title: local("ACTION_HIDEJB"), message: local("HIDE_NOTICE"), destructiveBtnTitle: local("PROCEED"), destructiveHandler: {
                    if (!envInfo.isRootful && FileManager.default.fileExists(atPath: "/var/jb")) {
                        do { try FileManager.default.removeItem(at: URL(fileURLWithPath: "/var/jb")) }
                        catch { log(type: .error, msg: "Failed to remove /var/jb: \(error.localizedDescription)") }
                    }
                    
                    let ret = spawn(command: "/cores/binpack/sbin/shutdown", args: ["-r", "now"], root: true)
                    if (ret != 0) {
                        return
                    }
                    
                })
                viewController.present(alert, animated: true)
            default:
                if (envInfo.isSimulator) {
                    let alert = UIAlertController.warning(title: local("ACTION_HIDEJB"), message: local("HIDE_NOTICE"), destructiveBtnTitle: local("PROCEED"), destructiveHandler: {
                    })
                    viewController.present(alert, animated: true)
                } else {
                    let errorAlert = UIAlertController.error(title: local("NO_PROCEED"), message: "\(local("STRAP_INFO")) \(strapValue)")
                    viewController.present(errorAlert, animated: true)
                }
            }
        } else {
            let errorAlert = UIAlertController.error(title: local("NO_PROCEED"), message: local("NOTICE_ROOTLESS"))
            viewController.present(errorAlert, animated: true)
            return
        }
    }
    @objc func switchToggled(_ sender: UISwitch) {
        envInfo.rebootAfter.toggle()
    }
}
