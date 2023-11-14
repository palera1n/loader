//
//  Options.swift
//  palera1nLoader
//
//  Created by samara on 11/13/23.
//

import Foundation
import UIKit

class OptionsVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    var tableData = [
        ["json", LocalizationManager.shared.local("DEBUG_CLEAR_JSON")],
        [LocalizationManager.shared.local("FR_SWITCH")],
        [LocalizationManager.shared.local("LOG_CELL_VIEW"), LocalizationManager.shared.local("ACTIONS"), LocalizationManager.shared.local("DIAGNOSTICS")]
    ]
    
    var customMessage: String?
    
    var sectionTitles = ["JSON", LocalizationManager.shared.local("DEBUG_OPTIONS"), "ADVANCED"]
    
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
        
        self.title = LocalizationManager.shared.local("DEBUG_OPTIONS")

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
        cell.accessoryType = .none
        cell.imageView?.image = nil

        switch tableData[indexPath.section][indexPath.row] {
        case LocalizationManager.shared.local("DEBUG_CLEAR_JSON"):
            cell.textLabel?.text = LocalizationManager.shared.local("DEBUG_CLEAR_JSON")
            cell.textLabel?.textColor = .systemBlue
        case LocalizationManager.shared.local("DIAGNOSTICS"):
            cell.textLabel?.text = LocalizationManager.shared.local("DIAGNOSTICS")
            cell.accessoryType = .disclosureIndicator
        case LocalizationManager.shared.local("ACTIONS"):
            cell.textLabel?.text = LocalizationManager.shared.local("ACTIONS")
            cell.accessoryType = .disclosureIndicator
        case LocalizationManager.shared.local("FR_SWITCH"):
            let switchControl = UISwitch()
            switchControl.isOn = envInfo.rebootAfter
            switchControl.addTarget(self, action: #selector(switchToggled(_:)), for: .valueChanged)
            cell.accessoryView = switchControl
            cell.textLabel?.text = LocalizationManager.shared.local("FR_SWITCH")
            cell.selectionStyle = .none
        case "json":
            let textField = UITextField()
            textField.placeholder = "https://palera.in/loader.json"
            textField.translatesAutoresizingMaskIntoConstraints = false
            cell.contentView.addSubview(textField)
            textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)

            textField.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16).isActive = true
            textField.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16).isActive = true
            textField.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 10).isActive = true
            textField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -10).isActive = true

            cell.accessoryType = .none

        case LocalizationManager.shared.local("LOG_CELL_VIEW"):
            cell.textLabel?.text = LocalizationManager.shared.local("LOG_CELL_VIEW")
            cell.accessoryType = .disclosureIndicator

        default:
            break
        }
        
        return cell
    }
  
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == tableData.count - 3 {
            return  """
                    This will allow you to change where the loader application will download from with a custom URL to a json file, this can change the package manager, bootstrap, and repos included. If you don't know what you're doing, you can use the default configuration.
                    
                    Set currently: \"\(envInfo.jsonURI)\"
                    """
        } else if section == tableData.count - 1 {
            return """
            © 2023, palera1n team
            
            \(LocalizationManager.shared.local("CREDITS_SUBTEXT"))
            @ssalggnikool & @staturnzdev
            """
        }
        return nil
    }
  
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemTapped = tableData[indexPath.section][indexPath.row]
        switch itemTapped {
        case LocalizationManager.shared.local("DEBUG_CLEAR_JSON"):
          resetField()
          UIApplication.shared.openSpringBoard()
          exit(0)
        case LocalizationManager.shared.local("LOG_CELL_VIEW"):
            let lv = LogListVC()

            navigationController?.pushViewController(lv, animated: true)
        case LocalizationManager.shared.local("ACTIONS"):
          let actionsVC = ActionsVC()

            navigationController?.pushViewController(actionsVC, animated: true)
        case LocalizationManager.shared.local("DIAGNOSTICS"):
            let dVC = DiagnosticsVC()

              navigationController?.pushViewController(dVC, animated: true)
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
    
    @objc private func resetField() {
        UserDefaults.standard.set("https://palera.in/loader.json", forKey: "JsonURI")
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if let newValue = textField.text {
            if !newValue.isEmpty, newValue.hasSuffix(".json"), newValue.contains("://") {
                UserDefaults.standard.set(newValue, forKey: "JsonURI")
            }
        }
    }

}
