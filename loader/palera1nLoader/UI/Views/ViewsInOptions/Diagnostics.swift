//
//  DiagnosticsVC.swift
//  palera1nLoader
//
//  Created by samara on 4/22/23.
//

import UIKit
import MachO
import Extras
class DiagnosticsVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableData = [
        [LocalizationManager.shared.local("TYPE_INFO"), LocalizationManager.shared.local("KINFO_FLAGS"), LocalizationManager.shared.local("PINFO_FLAGS")],
        [LocalizationManager.shared.local("VERSION_INFO"), LocalizationManager.shared.local("ARCH_INFO"), "Device ID", "Kernel", "CF"],

        
        [LocalizationManager.shared.local("STRAP_INFO"), LocalizationManager.shared.local("INSTALL_FR")]
    ]
    var selectedCellText: String?
    let sectionTitles = ["palera1n", "iOS", LocalizationManager.shared.local("STRAP_INFO")]
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
    
    func getDeviceCode() -> String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        let modelCode = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                ptr in String.init(validatingUTF8: ptr)
            }
        }
        if modelCode!.contains("arm64") || modelCode!.contains("x86_64") {
            return "Simulated"
        }
        return modelCode
    }
    
    func bootargsObviouslyProbably() -> String {
        var size: size_t = 0
        sysctlbyname("kern.bootargs", nil, &size, nil, 0)

        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("kern.bootargs", &machine, &size, nil, 0)

        let bootArgs = String(cString: machine)
        return bootArgs
    }
    
    func kernelVersion() -> String {
        var utsnameInfo = utsname()
        uname(&utsnameInfo)

        let releaseCopy = withUnsafeBytes(of: &utsnameInfo.release) { bytes in
            Array(bytes)
        }

        let version = String(cString: releaseCopy)
        return version
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
        cell.selectionStyle = .none
        
        switch tableData[indexPath.section][indexPath.row] {
        case LocalizationManager.shared.local("VERSION_INFO"):
            cell.textLabel?.text = LocalizationManager.shared.local("VERSION_INFO")
            cell.detailTextLabel?.text = UIDevice.current.systemVersion
        case "Device ID":
            cell.textLabel?.text = "Device ID"
            cell.detailTextLabel?.text = getDeviceCode()
        case "Kernel":
            cell.textLabel?.text = "Kernel Version"
            cell.detailTextLabel?.text = kernelVersion()
        case "CF":
            cell.textLabel?.text = "CF Version"
            cell.detailTextLabel?.text = "\(Int(floor((kCFCoreFoundationVersionNumber))))"
        case LocalizationManager.shared.local("ARCH_INFO"):
            cell.textLabel?.text = LocalizationManager.shared.local("ARCH_INFO")
            cell.detailTextLabel?.text = String(cString: NXGetLocalArchInfo().pointee.name)
        case LocalizationManager.shared.local("TYPE_INFO"):
            cell.textLabel?.text = LocalizationManager.shared.local("TYPE_INFO")
            cell.detailTextLabel?.text = envInfo.isRootful ? LocalizationManager.shared.local("ROOTFUL") : LocalizationManager.shared.local("ROOTLESS")
        case LocalizationManager.shared.local("INSTALL_FR"):
            cell.textLabel?.text = LocalizationManager.shared.local("INSTALL_FR")
            cell.detailTextLabel?.text = envInfo.hasForceReverted ? LocalizationManager.shared.local("TRUE") : LocalizationManager.shared.local("FALSE")
        case LocalizationManager.shared.local("STRAP_INFO"):
            let strapValue = Check.installation()
            switch strapValue {
            case .rootful:
                cell.detailTextLabel?.text = LocalizationManager.shared.local("FALSE")
            case .simulated:
                cell.detailTextLabel?.text = "Simulated"
            case .rootless:
                cell.detailTextLabel?.text = LocalizationManager.shared.local("FALSE")
            case .rootless_installed:
                cell.detailTextLabel?.text = LocalizationManager.shared.local("TRUE")
            case .rootful_installed:
                cell.detailTextLabel?.text = LocalizationManager.shared.local("TRUE")
            }
            cell.textLabel?.text = LocalizationManager.shared.local("INSTALL_INFO")
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
            
            
            BOOT-ARGS
            
            \(bootargsObviouslyProbably())
            """
        }
        return nil
    }
}

