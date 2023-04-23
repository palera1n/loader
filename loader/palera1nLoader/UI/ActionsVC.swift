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
        [local("FR_SWITCH"), local("HIDE")],
        
        [local("OPENER_SILEO"), local("OPENER_ZEBRA"), local("OPENER_TH")],
        
        [local("RESPRING"), local("UICACHE"), local("TWEAKS"), local("US_REBOOT"), local("DAEMONS"), local("MOUNT")]
    ]
    
    let sectionTitles = ["", "OPENERS", "UTILITIES"]
    override func viewDidLoad() {
        if (!envInfo.hasChecked) { Utils().prerequisiteChecks() }
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
        
        cell.selectionStyle = .default
        
        switch tableData[indexPath.section][indexPath.row] {
        case local("FR_SWITCH"):
            applySymbolModifications(to: cell, with: "arrow.forward.circle", backgroundColor: .systemPurple)
            let switchControl = UISwitch()
            switchControl.isOn = envInfo.rebootAfter
            switchControl.addTarget(self, action: #selector(switchToggled(_:)), for: .valueChanged)
            cell.accessoryView = switchControl
            cell.textLabel?.text = "Reboot on revert"
            cell.selectionStyle = .none
        case local("HIDE"):
            applySymbolModifications(to: cell, with: "eye.slash.circle", backgroundColor: .systemIndigo)
            cell.textLabel?.text = local("HIDE")
            cell.accessoryType = .disclosureIndicator
            
        case local("OPENER_SILEO"):
            applySymbolModifications(to: cell, with: "arrow.uturn.forward", backgroundColor: .systemBlue)
            cell.textLabel?.text = "Open Sileo"
            cell.textLabel?.textColor = .systemBlue
        case local("OPENER_ZEBRA"):
            applySymbolModifications(to: cell, with: "arrow.uturn.forward", backgroundColor: .systemBlue)
            cell.textLabel?.text = "Open Zebra"
            cell.textLabel?.textColor = .systemBlue
        case local("OPENER_TH"):
            applySymbolModifications(to: cell, with: "arrow.uturn.forward", backgroundColor: .systemBlue)
            cell.textLabel?.text = "Open Trollhelper"
            cell.textLabel?.textColor = .systemBlue
            
        case local("RESPRING"):
            applySymbolModifications(to: cell, with: "arrow.counterclockwise.circle", backgroundColor: .systemBlue)
            cell.textLabel?.text = local("RESPRING")
            cell.textLabel?.textColor = .systemBlue
        case local("UICACHE"):
            applySymbolModifications(to: cell, with: "iphone.circle", backgroundColor: .systemBlue)
            cell.textLabel?.text = local("UICACHE")
            cell.textLabel?.textColor = .systemBlue
        case local("TWEAKS"):
            applySymbolModifications(to: cell, with: "hammer.circle", backgroundColor: .systemBlue)
            cell.textLabel?.text = local("TWEAKS")
            cell.textLabel?.textColor = .systemBlue
            
        case local("US_REBOOT"):
            applySymbolModifications(to: cell, with: "bolt.circle", backgroundColor: .systemOrange)
            cell.textLabel?.text = local("US_REBOOT")
            cell.textLabel?.textColor = .systemOrange
        case local("DAEMONS"):
            applySymbolModifications(to: cell, with: "eject.circle", backgroundColor: .systemOrange)
            cell.textLabel?.text = local("DAEMONS")
            cell.textLabel?.textColor = .systemOrange
        case local("MOUNT"):
            applySymbolModifications(to: cell, with: "tray.circle", backgroundColor: .systemOrange)
            cell.textLabel?.text = local("MOUNT")
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
        case local("HIDE"):
            HideEnv(viewController: self)
        case local("OPENER_SILEO"):
            if openApp("org.coolstar.SileoStore") {
            } else if openApp("org.coolstar.SileoNightly") {
            } else {
                print("Failed to open Sileo app")
            }
        case local("OPENER_ZEBRA"):
            if !openApp("xyz.willy.Zebra") {
                print("Failed to open Zebra app")
            }
        case local("OPENER_TH"):
            if !openApp("com.opa334.trollstorepersistencehelper") {
                print("Failed to open Trollhelper app")
            }
            
        case local("RESPRING"):
            spawn(command: "\(prefix)/usr/bin/sbreload", args: [], root: true)
        case local("UICACHE"):
            spawn(command: "\(prefix)/usr/bin/uicache", args: ["-a"], root: true)
        case local("TWEAKS"):
            if envInfo.isRootful {
                spawn(command: "/etc/rc.d/substitute-launcher", args: [], root: true)
            } else {
                spawn(command: "/var/jb/usr/libexec/ellekit/loader", args: [], root: true)
            }
            
        case local("US_REBOOT"):
            spawn(command: "\(prefix)/usr/bin/launchctl", args: ["reboot", "userspace"], root: true)
        case local("DAEMONS"):
            spawn(command: "\(prefix)/bin/launchctl", args: ["bootstrap", "system", "/var/jb/Library/LaunchDaemons"], root: true)
        case local("MOUNT"):
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true); spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func HideEnv(viewController: UIViewController) {
        if (!envInfo.isRootful) {
            let strapValue = envInfo.envType
            switch strapValue {
            case 1:
                let alert = UIAlertController.warning(title: local("HIDE"), message: local("HIDE_NOTICE"), destructiveBtnTitle: local("PROCEED"), destructiveHandler: {
                    if (envInfo.hasHelper) {
                        if (!envInfo.isRootful && FileManager.default.fileExists(atPath: "/var/jb")) {
                            do { try FileManager.default.removeItem(at: URL(fileURLWithPath: "/var/jb")) }
                            catch { NSLog("[palera1n helper] Failed with error \(error.localizedDescription)") }
                        }
                        
                        let ret = spawn(command: envInfo.helperPath, args: ["-d"], root: true)
                        if (ret != 0) {
                            return
                        }
                    }
                })
                viewController.present(alert, animated: true)
            default:
                if (envInfo.isSimulator) {
                    let alert = UIAlertController.warning(title: local("HIDE"), message: local("HIDE_NOTICE"), destructiveBtnTitle: local("PROCEED"), destructiveHandler: {
                    })
                    viewController.present(alert, animated: true)
                } else {
                    let errorAlert = UIAlertController.error(title: local("NO_PROCEED"), message: "\(local("STRAP_INFO")) \(strapValue)")
                    viewController.present(errorAlert, animated: true)
                }
            }
        } else {
            let errorAlert = UIAlertController.error(title: local("NO_PROCEED"), message: local("ROOTLESS_NOTICE"))
            viewController.present(errorAlert, animated: true)
            return
        }
    }
    @objc func switchToggled(_ sender: UISwitch) {
        envInfo.rebootAfter.toggle()
    }
}
