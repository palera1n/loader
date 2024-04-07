//
//  UtilitiesViewController.swift
//  palera1nLoader
//
//  Created by samara on 2/6/24.
//

import Foundation
import UIKit

class UtilitiesViewController: UIViewController {
    var tableView: UITableView!

    var tableData = [
        ["UICache", "Restart SpringBoard", "Userspace Reboot"]
    ]
  
    var sectionTitles = [
        String.localized("Utilities")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
        self.title = .localized("Utilities")
        self.determineIfUserShouldBeAbleToUseTheseButtons()
    }
    
    func setupViews() {
        self.tableView = UITableView(frame: .zero, style: .grouped)
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.view.addSubview(tableView)
        self.tableView.constraintCompletely(to: view)
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
        case "Restart SpringBoard", "UICache", "Userspace Reboot":
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
        case "Restart SpringBoard":
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
