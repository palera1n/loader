//
//  UtilitiesViewController.swift
//  palera1nLoader
//
//  Created by samara on 2/6/24.
//

import Foundation
import UIKit

class UtilitiesViewController: UIViewController {
    
    var tableData = [
        ["UICache", "Restart Springboard", "Userspace Reboot"]
    ]
  
    var sectionTitles = [String.localized("Utilities")]
    
    var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        title = .localized("Utilities")
        determineIfUserShouldBeAbleToUseTheseButtons()
    }
    
    func setupViews() {
        if #available(iOS 13.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            self.tableView = UITableView(frame: .zero, style: .insetGrouped)
        } else {
            self.tableView = UITableView(frame: .zero, style: .grouped)
        }
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.constraintCompletely(to: view)
    }
    
    func determineIfUserShouldBeAbleToUseTheseButtons() {
        if paleInfo.palerain_option_safemode || paleInfo.palerain_option_failure {
            tableData.insert([.localized("Exit Safemode")], at: tableData.count)
            sectionTitles.insert("palera1n", at: sectionTitles.count)
        }
    }
    
}

extension UtilitiesViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { return sectionTitles.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return tableData[section].count }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { return sectionTitles[section] }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return 40 }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad { return 60.0 } else { return UITableView.automaticDimension }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return .localized("Utilities Explanation")
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "Cell"
        let cell = UITableViewCell(style: .value1, reuseIdentifier: reuseIdentifier)
        cell.accessoryType = .none
        cell.selectionStyle = .default
        
        let cellText = tableData[indexPath.section][indexPath.row]
        cell.textLabel?.text = cellText
        switch cellText {
        case "Restart Springboard", "UICache", "Userspace Reboot":
            cell.textLabel?.textColor = .systemBlue
        case .localized("Exit Safemode"), "Revert Snapshot":
            cell.textLabel?.textColor = .systemRed
            cell.accessoryType = .disclosureIndicator
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemTapped = tableData[indexPath.section][indexPath.row]
        switch itemTapped {
        case "Restart Springboard":
            spawn(command: "/cores/binpack/bin/launchctl", args: ["kickstart", "-k", "system/com.apple.backboardd"])
        case "Userspace Reboot":
            spawn(command: "/cores/binpack/bin/launchctl", args: ["reboot", "userspace"])
        case "UICache":
            spawn(command: "/cores/binpack/usr/bin/uicache", args: ["-a"])
        case .localized("Exit Safemode"):
            ExitFailureSafeMode()
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
