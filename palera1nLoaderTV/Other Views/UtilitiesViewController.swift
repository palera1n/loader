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
        ["UICache", "Restart PineBoard", "Userspace Reboot"]
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
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        let imageView = UIImageView(image: UIImage(named: "apple-tv"))
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0.5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(imageView)
        
        self.tableView = UITableView(frame: .zero, style: .grouped)
        self.tableView.register(ErrorCell.self, forCellReuseIdentifier: ErrorCell.reuseIdentifier)
        self.tableView.register(LoadingCell.self, forCellReuseIdentifier: LoadingCell.reuseIdentifier)
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        stackView.addArrangedSubview(tableView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            imageView.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.5),
            imageView.heightAnchor.constraint(equalTo: stackView.heightAnchor) // I
        ])
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
        case "Restart PineBoard", "UICache", "Userspace Reboot":
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
        case "Restart PineBoard":
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
