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
    
    var tableView: UITableView!

    var tableData = [
        [String.localized("Type"), String.localized("Flags")],
        [String.localized("Version"), String.localized("Architecture"), "Kernel", "CF"],
        ["App Version"]
    ]

    var sectionTitles: [String] {
        #if os(tvOS)
        return ["", device, ""]
        #else
        return ["palera1n", device, "App Info"]
        #endif
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
        self.title = String.localized("About")
    }
    
    func setupViews() {
        self.tableView = UITableView(frame: .zero, style: .grouped)
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.dataSource = self
        self.tableView.delegate = self

        #if os(tvOS)
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

        self.tableView.allowsSelection = false

        stackView.addArrangedSubview(tableView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            imageView.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.5),
            imageView.heightAnchor.constraint(equalTo: stackView.heightAnchor) // I
        ])
        #else
        self.view.addSubview(tableView)
        self.tableView.constraintCompletely(to: view)
        #endif
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
        case "App Version":
            if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                cell.detailTextLabel?.text = appVersion
            }
        case String.localized("Credits"):
            cell.accessoryType = .disclosureIndicator
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
    fileprivate func deviceBoot_Args() -> String {
        var size: size_t = 0
        sysctlbyname("kern.bootargs", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("kern.bootargs", &machine, &size, nil, 0)
        let bootArgs = String(cString: machine)
        return bootArgs
    }
    
    fileprivate func kernelVersion() -> String {
        var utsnameInfo = utsname()
        uname(&utsnameInfo)
        
        let releaseCopy = withUnsafeBytes(of: &utsnameInfo.release) { bytes in
            Array(bytes)
        }
        
        let version = String(cString: releaseCopy)
        return version
    }
}
