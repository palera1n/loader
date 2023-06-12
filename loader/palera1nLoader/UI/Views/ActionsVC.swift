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
        [local("ACTION_HIDEJB")],
        
        [local("OPENER_SILEO"), local("OPENER_ZEBRA"), local("OPENER_TH")],
        
        [local("ACTION_RESPRING"), local("ACTION_UICACHE"), local("ACTION_TWEAKS")],
        
        [local("ACTION_USREBOOT"), local("ACTION_DAEMONS"), local("ACTION_MOUNT")]
    ]
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        envInfo.nav = navigationController!
    }
  
    var sectionTitles = ["", local("OPEN_CELL"), local("UTIL_CELL"), ""]
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.title = local("ACTIONS")
        
        let tableView = UITableView(frame: view.bounds, style: .insetGrouped)
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
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        
        switch tableData[indexPath.section][indexPath.row] {
        case local("ACTION_HIDEJB"):
            mods.applySymbolModifications(to: cell, with: "eye.slash.circle", backgroundColor: .systemIndigo)
            cell.textLabel?.text = local("ACTION_HIDEJB")
        case local("OPENER_SILEO"):
            mods.applySymbolModifications(to: cell, with: "arrow.uturn.forward", backgroundColor: .systemGray)
            cell.textLabel?.text = local("OPENER_SILEO")
        case local("OPENER_ZEBRA"):
            mods.applySymbolModifications(to: cell, with: "arrow.uturn.forward", backgroundColor: .systemGray)
            cell.textLabel?.text = local("OPENER_ZEBRA")
        case local("OPENER_TH"):
            mods.applySymbolModifications(to: cell, with: "arrow.uturn.forward", backgroundColor: .systemGray)
            cell.textLabel?.text = local("OPENER_TH")
            
        case local("ACTION_RESPRING"):
            mods.applySymbolModifications(to: cell, with: "arrow.counterclockwise.circle", backgroundColor: .systemBlue)
            cell.textLabel?.text = local("ACTION_RESPRING")
        case local("ACTION_UICACHE"):
            mods.applySymbolModifications(to: cell, with: "iphone.circle", backgroundColor: .systemPurple)
            cell.textLabel?.text = local("ACTION_UICACHE")
        case local("ACTION_TWEAKS"):
            mods.applySymbolModifications(to: cell, with: "hammer.circle", backgroundColor: .systemPink)
            cell.textLabel?.text = local("ACTION_TWEAKS")
            
        case local("ACTION_USREBOOT"):
            mods.applySymbolModifications(to: cell, with: "bolt.circle", backgroundColor: .systemOrange)
            cell.textLabel?.text = local("ACTION_USREBOOT")
            cell.textLabel?.textColor = .systemOrange
        case local("ACTION_DAEMONS"):
            mods.applySymbolModifications(to: cell, with: "eject.circle", backgroundColor: .systemOrange)
            cell.textLabel?.text = local("ACTION_DAEMONS")
            cell.textLabel?.textColor = .systemOrange
        case local("ACTION_MOUNT"):
            mods.applySymbolModifications(to: cell, with: "tray.circle", backgroundColor: .systemOrange)
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
            if opener.openApp("org.coolstar.SileoStore") {} else if opener.openApp("org.coolstar.SileoNightly") {}
        case local("OPENER_ZEBRA"):
            if opener.openApp("xyz.willy.Zebra") {}
        case local("OPENER_TH"):
            opener.TrollHelper()
        case local("ACTION_RESPRING"):
            spawn(command: "/cores/binpack/bin/launchctl", args: ["kickstart", "-k", "system/com.apple.backboardd"], root: true)
        case local("ACTION_UICACHE"):
            spawn(command: "\(prefix)/usr/bin/uicache", args: ["-a"], root: true)
        case local("ACTION_TWEAKS"):
            helper(args: ["-l"])
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { spawn(command: "/cores/binpack/bin/launchctl", args: ["kickstart", "-k", "system/com.apple.backboardd"], root: true) }
        case local("ACTION_USREBOOT"):
            spawn(command: "/cores/binpack/bin/launchctl", args: ["reboot", "userspace"], root: true)
        case local("ACTION_DAEMONS"):
            helper(args: ["-L"])
        case local("ACTION_MOUNT"):
            helper(args: ["-M"])
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case tableData.count - 1:
            return local("ACTION_MOUNT_SUBTEXT")
        case tableData.count - 3:
            return local("OPENER_SUBTEXT")
        default:
            return nil
        }
    }
    
    private func HideEnv(viewController: UIViewController) {
        if (!envInfo.isRootful) {
            let strapValue = envInfo.envType
            switch strapValue {
            case 1:
                #if !targetEnvironment(simulator)
                let alert = UIAlertController.warning(title: local("ACTION_HIDEJB"), message: local("HIDE_NOTICE"), destructiveBtnTitle: local("PROCEED"), destructiveHandler: {
                    if fileExists("/var/mobile/Library/palera1n/helper") {
                        if (!envInfo.isRootful) && fileExists("/var/jb") {
                            binpack.rm("/var/jb")
                        }
                        spawn(command: "/cores/binpack/bin/launchctl", args: ["reboot"], root: true)
                    }
                })
                viewController.present(alert, animated: true)
                #endif
            default:
                let errorAlert = UIAlertController.error(title: local("NO_PROCEED"), message: "\(local("STRAP_INFO")) \(strapValue)")
                viewController.present(errorAlert, animated: true)
            }
        } else {
            let errorAlert = UIAlertController.error(title: local("NO_PROCEED"), message: local("NOTICE_ROOTLESS"))
            viewController.present(errorAlert, animated: true)
            return
        }
    }
}
