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
        [local("LOG_CELL_VIEW")],
       // [local("DEBUG_CLEAN_FAKEFS"), local("DEBUG_ENTER_SAFEMODE"), local("DEBUG_EXIT_SAFEMODE"), local("LOG_CLEAR")],
        [local("DEBUG_CLEAN_FAKEFS"), local("LOG_CLEAR")],
        [local("FR_SWITCH")]
    ]
    
    var customMessage: String?
    
    var sectionTitles = ["", local("DEBUG_OPTIONS"), ""]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.title = local("DEBUG_CELL")
        
        let appearance = UINavigationBarAppearance()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .done, target: self, action: #selector(closeSheet))
        
        let tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
        case local("FR_SWITCH"):
            applySymbolModifications(to: cell, with: "arrow.forward.circle", backgroundColor: .systemPurple)
            let switchControl = UISwitch()
            switchControl.isOn = envInfo.rebootAfter
            switchControl.addTarget(self, action: #selector(switchToggled(_:)), for: .valueChanged)
            cell.accessoryView = switchControl
            cell.textLabel?.text = local("FR_SWITCH")
            cell.selectionStyle = .none
        case local("DEBUG_CLEAN_FAKEFS"):
            if envInfo.isRootful {
                cell.isUserInteractionEnabled = true
                cell.imageView?.alpha = 1
            } else if !envInfo.isRootful {
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textColor = .gray
                cell.accessoryType = .none
                cell.imageView?.alpha = 0.4
            }
            applySymbolModifications(to: cell, with: "fanblades", backgroundColor: .systemRed)
            cell.textLabel?.text = local("DEBUG_CLEAN_FAKEFS")
//        case local("DEBUG_ENTER_SAFEMODE"):
//            applySymbolModifications(to: cell, with: "checkerboard.shield", backgroundColor: .systemGreen)
//            cell.textLabel?.text = local("DEBUG_ENTER_SAFEMODE")
//        case local("DEBUG_EXIT_SAFEMODE"):
//            applySymbolModifications(to: cell, with: "shield.slash", backgroundColor: .systemRed)
//            cell.textLabel?.text = local("DEBUG_EXIT_SAFEMODE")
        case local("LOG_CLEAR"):
            applySymbolModifications(to: cell, with: "folder.badge.minus", backgroundColor: .systemRed)
            cell.textLabel?.text = local("LOG_CLEAR")
        case local("LOG_CELL_VIEW"):
            cell.textLabel?.text = local("LOG_CELL_VIEW")
            cell.textLabel?.textColor = .systemBlue
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemTapped = tableData[indexPath.section][indexPath.row]
        switch itemTapped {
        case local("LOG_CELL_VIEW"):
            log(type: .info, msg: "Opening Log View")
            let LogViewVC = LogViewer()
            navigationController?.pushViewController(LogViewVC, animated: true)
//        case local("DEBUG_ENTER_SAFEMODE"):
//            let alertController = whichAlert(title: "\(local("DEBUG_ENTER_SAFEMODE"))?", message: nil)
//            let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
//            let confirmAction = UIAlertAction(title: local("CONFIRM"), style: .default) {_ in helper(args: ["--safemode", "1"]) }
//            alertController.addAction(cancelAction)
//            alertController.addAction(confirmAction)
//            present(alertController, animated: true, completion: nil)
//        case local("DEBUG_EXIT_SAFEMODE"):
//            let alertController = whichAlert(title: "\(local("DEBUG_EXIT_SAFEMODE"))?", message: nil)
//            let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
//            let confirmAction = UIAlertAction(title: local("CONFIRM"), style: .default) {_ in helper(args: ["--safemode", "0"]) }
//            alertController.addAction(cancelAction)
//            alertController.addAction(confirmAction)
//            present(alertController, animated: true, completion: nil)
        case local("DEBUG_CLEAN_FAKEFS"):
            let alertController = whichAlert(title: "\(local("DEBUG_CLEAN_FAKEFS"))?", message: nil)
            let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
            let confirmAction = UIAlertAction(title: local("CONFIRM"), style: .destructive) {_ in helper(args: ["--revert-install"]) }
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        case local("LOG_CLEAR"):
            let files = try! FileManager.default.contentsOfDirectory(atPath: "/var/mobile/Library/palera1n/logs")
            for file in files {
                bp_rm("/var/mobile/Library/palera1n/logs/\(file)")
            }
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text, let range = Range(range, in: text) {
            customMessage = text.replacingCharacters(in: range, with: string)
        } else {
            customMessage = string
        }
        return true
    }
    
    @objc func switchToggled(_ sender: UISwitch) {
        envInfo.rebootAfter.toggle()
    }
}
