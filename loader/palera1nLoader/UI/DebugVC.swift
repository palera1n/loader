//
//  DebugVC.swift
//  palera1nLoader
//
//  Created by samara on 5/12/23.
//

import Foundation
import UIKit

class DebugVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    var tableData = [
        ["View Logs"],
        ["Enter safemode", "Exit safemode"],
        [local("FR_SWITCH")],
        ["Clean fakefs", local("REVERT_CELL")]
    ]
    
    var customMessage: String?
    
    var sectionTitles = ["", "SETTINGS", "", ""]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.systemGray6
        self.title = "Settings"
        
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .done, target: self, action: #selector(closeSheet))
        
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
        dismiss(animated: true, completion: nil)
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
        cell.accessoryType = .disclosureIndicator
        
        switch tableData[indexPath.section][indexPath.row] {
        case local("REVERT_CELL"):
            if envInfo.isRootful {
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textColor = .gray
                cell.imageView?.alpha = 0.4
            } else if !envInfo.isRootful {
                let isProcursusStrapped = FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped")
                cell.isUserInteractionEnabled = isProcursusStrapped
                cell.textLabel?.textColor = isProcursusStrapped ? .systemRed : .gray
                cell.accessoryType = isProcursusStrapped ? .disclosureIndicator : .none
                cell.imageView?.alpha = cell.isUserInteractionEnabled ? 1.0 : 0.4
            } else {
                cell.isUserInteractionEnabled = false
            }
            applySymbolModifications(to: cell, with: "trash", backgroundColor: .systemRed)
            cell.textLabel?.text = local("REVERT_CELL")
        case local("FR_SWITCH"):
            applySymbolModifications(to: cell, with: "arrow.forward.circle", backgroundColor: .systemPurple)
            let switchControl = UISwitch()
            switchControl.isOn = envInfo.rebootAfter
            switchControl.addTarget(self, action: #selector(switchToggled(_:)), for: .valueChanged)
            cell.accessoryView = switchControl
            cell.textLabel?.text = local("FR_SWITCH")
            cell.selectionStyle = .none
        case "Clean fakefs":
            applySymbolModifications(to: cell, with: "fanblades", backgroundColor: .systemRed)
            cell.textLabel?.text = "Clean fakefs"
        case "Enter safemode":
            applySymbolModifications(to: cell, with: "checkerboard.shield", backgroundColor: .systemGreen)
            cell.textLabel?.text = "Enter safemode"
        case "Exit safemode":
            applySymbolModifications(to: cell, with: "shield.slash", backgroundColor: .systemRed)
            cell.textLabel?.text = "Exit safemode"
        case "View Logs":
            cell.textLabel?.text = "View Logs"
            cell.textLabel?.textColor = .systemBlue
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemTapped = tableData[indexPath.section][indexPath.row]
        switch itemTapped {
        case local("REVERT_CELL"):
            let alertController = whichAlert(title: local("CONFIRM"), message: local("REVERT_WARNING"))
            let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
            let confirmAction = UIAlertAction(title: local("REVERT_CELL"), style: .destructive) {_ in revert(viewController: self) }
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        case "View Logs":
            log(type: .info, msg: "Opening Log View")
            let LogViewVC = LogViewer()
            navigationController?.pushViewController(LogViewVC, animated: true)
        case "Enter safemode":
            log(type: .info, msg: "Enter SM")
        case "Exit safemode":
            log(type: .info, msg: "Exit SM")
        case "Clean fakefs":
            log(type: .info, msg: "Pressed fakefs")
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    @objc func switchToggled(_ sender: UISwitch) {
        envInfo.rebootAfter.toggle()
    }
}
