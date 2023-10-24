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
        [LocalizationManager.shared.local("LOG_CELL_VIEW")],
        ["json"],
        [LocalizationManager.shared.local("DEBUG_CLEAR_JSON"),
         LocalizationManager.shared.local("FR_SWITCH")]
    ]
    
    var customMessage: String?
    
    var sectionTitles = ["", "JSON", LocalizationManager.shared.local("DEBUG_OPTIONS")]
    
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
        
        self.title = LocalizationManager.shared.local("DEBUG_CELL")

        navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .done, target: self, action: #selector(closeSheet))
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
        case LocalizationManager.shared.local("DEBUG_CLEAR_JSON"):
            if #available(iOS 13.0, *) {
                mods.applySymbolModifications(to: cell, with: "arrow.clockwise", backgroundColor: .systemGray)
            } else {
                cell.imageView?.image = nil
            }
            cell.textLabel?.text = LocalizationManager.shared.local("DEBUG_CLEAR_JSON")
        case LocalizationManager.shared.local("FR_SWITCH"):
            if #available(iOS 13.0, *) {
                mods.applySymbolModifications(to: cell, with: "arrow.forward.circle", backgroundColor: .systemPurple)
            } else {
                cell.imageView?.image = nil
            }
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
            textField.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8).isActive = true
            textField.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8).isActive = true

            cell.accessoryType = .none

        case LocalizationManager.shared.local("LOG_CELL_VIEW"):
            cell.textLabel?.text = LocalizationManager.shared.local("LOG_CELL_VIEW")
            cell.textLabel?.textColor = .systemBlue
        default:
            break
        }
        
        return cell
    }
  
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == tableData.count - 2 {
            return "WARNING: JSON functionality is limited at its current state, don't use unless you know what you're doing.\n\nSet currently: \"\(envInfo.jsonURI)\""
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
            log(type: .info, msg: "Opening Log View")
            let LogViewVC = LogViewer()
            navigationController?.pushViewController(LogViewVC, animated: true)
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
      log(msg: "[JSON EDITING] https://palera.in/loader.json")
      UserDefaults.standard.set("https://palera.in/loader.json", forKey: "JsonURI")
    }
        
    @objc private func textFieldDidChange(_ textField: UITextField) {
        if let newValue = textField.text {
            log(msg: "[JSON EDITING] \(newValue)")
            UserDefaults.standard.set(newValue, forKey: "JsonURI")
      }
    }
}
