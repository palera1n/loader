//
//  DiagnosticsVC.swift
//  palera1nLoader
//
//  Created by samara on 4/22/23.
//

import UIKit
import MachO

class DiagnosticsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableData = [
        [LocalizationManager.shared.local("VERSION_INFO"), LocalizationManager.shared.local("ARCH_INFO")],
        
        [LocalizationManager.shared.local("TYPE_INFO"), LocalizationManager.shared.local("KINFO_FLAGS"), LocalizationManager.shared.local("PINFO_FLAGS")],
        
        [LocalizationManager.shared.local("STRAP_INFO")]
    ]
    var selectedCellText: String?
    let sectionTitles = ["", "PALERA1N", LocalizationManager.shared.local("STRAP_INFO")]
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

        self.title = LocalizationManager.shared.local("DIAGNOSTICS")
        
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        tableView.delegate = self
        tableView.dataSource = self
        
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
    
    @available(iOS 13.0, *)
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            guard let cell = gestureRecognizer.view as? UITableViewCell else {
                return
            }
            
            let text = cell.detailTextLabel?.text
            if let text = text {
                selectedCellText = text
                let menuController = UIMenuController.shared
                let copyItem = UIMenuItem(title: LocalizationManager.shared.local("COPY"), action: #selector(copyText))
                menuController.menuItems = [copyItem]
                menuController.showMenu(from: cell, rect: cell.bounds)
            }
        }
    }

    @objc func copyText() {
        if let text = selectedCellText {
            UIPasteboard.general.string = text
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "Cell"
        let cell = UITableViewCell(style: .value1, reuseIdentifier: reuseIdentifier)
        if #available(iOS 13.0, *) {
            let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
            cell.addGestureRecognizer(longPressRecognizer)
        }
        cell.selectionStyle = .none
        
        switch tableData[indexPath.section][indexPath.row] {
        case LocalizationManager.shared.local("VERSION_INFO"):
            cell.textLabel?.text = LocalizationManager.shared.local("VERSION_INFO")
            cell.detailTextLabel?.text = UIDevice.current.systemVersion
        case LocalizationManager.shared.local("ARCH_INFO"):
            cell.textLabel?.text = LocalizationManager.shared.local("ARCH_INFO")
            cell.detailTextLabel?.text = String(cString: NXGetLocalArchInfo().pointee.name)
        case LocalizationManager.shared.local("TYPE_INFO"):
            cell.textLabel?.text = LocalizationManager.shared.local("TYPE_INFO")
            cell.detailTextLabel?.text = envInfo.isRootful ? LocalizationManager.shared.local("ROOTFUL") : LocalizationManager.shared.local("ROOTLESS")
        case LocalizationManager.shared.local("INSTALL_FR"):
            cell.textLabel?.text = LocalizationManager.shared.local("INSTALL_FR")
            cell.detailTextLabel?.text = envInfo.hasForceReverted ? LocalizationManager.shared.local("TRUE") : LocalizationManager.shared.local("FALSE")
        case LocalizationManager.shared.local("KINFO_FLAGS"):
            cell.textLabel?.text = LocalizationManager.shared.local("KINFO_FLAGS")
            cell.detailTextLabel?.text = envInfo.kinfoFlags
        case LocalizationManager.shared.local("PINFO_FLAGS"):
            cell.textLabel?.text = LocalizationManager.shared.local("PINFO_FLAGS")
            cell.detailTextLabel?.text = envInfo.pinfoFlags
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == tableData.count - 1 {
            return """
            © 2023, palera1n team
            
            \(LocalizationManager.shared.local("CREDITS_SUBTEXT"))
            @ssalggnikool (Samara) & @staturnzdev (Staturnz)
            """
        }
        return nil
    }
}

