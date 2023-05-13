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
        ["Flags (paleinfo)", "Set p1 Flags"],
        ["Flags (kerninfo)", "Set kerninfo Flags"],
        ["View Logs"],
        ["Clean fakefs", "Enter safemode", "Exit safemode"],
        [local("FR_SWITCH")]
    ]
    
    var customMessage: String?
    
    var sectionTitles = ["", "", "", "OPTIONS", ""]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.title = "Debug"
        
        let appearance = UINavigationBarAppearance()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: .done, target: self, action: #selector(closeSheet))
        
        let tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
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
        case "Clean fakefs":
            applySymbolModifications(to: cell, with: "eraser.fill", backgroundColor: .systemRed)
            cell.textLabel?.text = "Clean fakefs"
        case "Enter safemode":
            applySymbolModifications(to: cell, with: "checkerboard.shield", backgroundColor: .systemGreen)
            cell.textLabel?.text = "Enter safemode"
        case "Exit safemode":
            applySymbolModifications(to: cell, with: "shield.slash", backgroundColor: .systemRed)
            cell.textLabel?.text = "Exit safemode"
        case "Flags (paleinfo)":
            let textField = UITextField(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
            textField.placeholder = "Enter custom flags"
            textField.borderStyle = .roundedRect
            textField.backgroundColor = UIColor.systemGray6
            textField.delegate = self
            cell.accessoryView = textField
            
            cell.textLabel?.text = "paleinfo"
        case "Set p1 Flags":
            cell.textLabel?.text = "Set paleinfo flags"
            cell.textLabel?.textColor = .systemBlue
        case "View Logs":
            cell.textLabel?.text = "View Logs"
            cell.textLabel?.textColor = .systemBlue
        case "Flags (kerninfo)":
            let textField = UITextField(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
            textField.placeholder = "Enter custom flags"
            textField.borderStyle = .roundedRect
            textField.backgroundColor = UIColor.systemGray6
            textField.delegate = self
            cell.accessoryView = textField
            
            cell.textLabel?.text = "kerninfo"
        case "Set kerninfo Flags":
            cell.textLabel?.text = "Set kerninfo flags"
            cell.textLabel?.textColor = .systemBlue
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemTapped = tableData[indexPath.section][indexPath.row]
        switch itemTapped {
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
        case "Set p1 Flags":
            print("Custom message: \(customMessage ?? "")")
        case "Set kerninfo Flags":
            print("Custom message: \(customMessage ?? "")")
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
