//
//  InfoViewController.swift
//  palera1nLoader
//
//  Created by samara on 2/6/24.
//

import Foundation
import UIKit
import MachO

class InfoViewController: UIViewController {
    
    var tableData = [
        [String.localized("Type"), String.localized("Flags")],
        [String.localized("Version"), String.localized("Architecture")],
        ["Kernel", "CF"]
    ]
    var device: String {
        return UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone"
    }

    var sectionTitles: [String] {
        return ["palera1n", device, ""]
    }
    
    var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        title = String.localized("About")
    }
    
    func setupViews() {
        self.tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.constraintCompletely(to: view)
    }
}
extension InfoViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { return sectionTitles.count }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return tableData[section].count }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { return sectionTitles[section] }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return 40 }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "Cell"
        let cell = UITableViewCell(style: .value1, reuseIdentifier: reuseIdentifier)
        cell.selectionStyle = .none
        
        let cellText = tableData[indexPath.section][indexPath.row]
        cell.textLabel?.text = cellText
        switch cellText {
        case String.localized("Version"):
            cell.detailTextLabel?.text = UIDevice.current.systemVersion
        case "Kernel":
            cell.detailTextLabel?.text = kernelVersion()
        case "CF":
            cell.detailTextLabel?.text = "\(Int(floor((kCFCoreFoundationVersionNumber))))"
        case String.localized("Architecture"):
            cell.detailTextLabel?.text = String(cString: NXGetLocalArchInfo().pointee.name)
        case String.localized("Type"):
            cell.detailTextLabel?.text = paleInfo.palerain_option_rootful ? "Rootful" : "Rootless"
        case String.localized("Flags"):
            cell.detailTextLabel?.text = String(format: "0x%llx", GetPinfoFlags())
        default:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == tableData.count - 1 {
            return """
            
            
            BOOT-ARGS
            
            \(deviceBoot_Args())
            """
        }
        return nil
    }
}
extension InfoViewController {
    private func deviceBoot_Args() -> String {
         var size: size_t = 0
         sysctlbyname("kern.bootargs", nil, &size, nil, 0)
         var machine = [CChar](repeating: 0, count: size)
         sysctlbyname("kern.bootargs", &machine, &size, nil, 0)
         let bootArgs = String(cString: machine)
         return bootArgs
     }
     
    private  func kernelVersion() -> String {
         var utsnameInfo = utsname()
         uname(&utsnameInfo)
         
         let releaseCopy = withUnsafeBytes(of: &utsnameInfo.release) { bytes in
             Array(bytes)
         }
         
         let version = String(cString: releaseCopy)
         return version
     }
}
