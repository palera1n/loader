//
//  ViewController.swift
//  pockiiau
//
//  Created by samiiau on 2/27/23.
//  Copyright © 2023 samiiau. All rights reserved.
//

import UIKit
import LaunchServicesBridge
import CoreServices
import MachO

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var rootful : Bool = false
    var inst_prefix: String = "unset"

    var tableData = [["Sileo", "Zebra"], ["Utilities", "Openers", "Revert Install"]]
    let sectionTitles = ["INSTALL", "DEBUG"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appearance = UINavigationBarAppearance()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance

        let customView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        customView.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 25).isActive = true
        button.heightAnchor.constraint(equalToConstant: 25).isActive = true
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.setBackgroundImage(UIImage(named: "AppIcon"), for: .normal)
        customView.addSubview(button)
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "palera1n"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        customView.addSubview(titleLabel)

        button.leadingAnchor.constraint(equalTo: customView.leadingAnchor).isActive = true
        button.centerYAnchor.constraint(equalTo: customView.centerYAnchor).isActive = true

        titleLabel.leadingAnchor.constraint(equalTo: button.trailingAnchor, constant: 8).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: customView.centerYAnchor).isActive = true

        let customBarButton = UIBarButtonItem(customView: customView)
        navigationItem.leftBarButtonItems = [customBarButton]


        let tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)

        // Check for root permissions // also include checks if user is able to use Loader
        if (inst_prefix == "unset") {
        #if targetEnvironment(simulator)
        #else
            guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
                let alertController = errorAlert(title: "Could not find helper?", message: "If you've sideloaded this loader app unfortunately you aren't able to use this, please jailbreak with palera1n before proceeding.")
                print("[palera1n] Could not find helper?")
                self.present(alertController, animated: true, completion: nil)
                return
            }
            
            let ret = spawn(command: helper, args: ["-f"], root: true)
            rootful = ret == 0 ? false : true
            inst_prefix = rootful ? "" : "/var/jb"
            
            let retRFR = spawn(command: helper, args: ["-n"], root: true)
            let rfr = retRFR == 0 ? false : true
            if rfr {
                let alertController = errorAlert(title: "Unable to continue", message: "Bootstrapping after using --force-revert is not supported, please rejailbreak to be able to bootstrap again.")
                self.present(alertController, animated: true, completion: nil)
                return
            }
        #endif
        }
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].count
    }
    
    // MARK: - Viewtable for Cydia/Zebra/Restore Rootfs cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = tableData[indexPath.section][indexPath.row]
        
        if tableData[indexPath.section][indexPath.row] == "Revert Install" {
            if FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                cell.isHidden = false
                cell.isUserInteractionEnabled = true
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.textColor = .systemRed
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped"){
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textColor = .gray
                cell.detailTextLabel?.text = "Rootful cannot use this button :("
                cell.selectionStyle = .none
            } else {
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textColor = .gray
                cell.selectionStyle = .none
            }
        } else if tableData[indexPath.section][indexPath.row] == "Sileo" || tableData[indexPath.section][indexPath.row] == "Zebra" {
            guard Bundle.main.path(forAuxiliaryExecutable: "Helper") != nil else {
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textColor = .gray
                cell.selectionStyle = .default
                return cell
            };
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
            cell.detailTextLabel?.text = tableData[indexPath.section][indexPath.row] == "Sileo" ? "Modern package manager" : "Familiar looking package manager"
            cell.selectionStyle = .default
        }
        
        if tableData[indexPath.section][indexPath.row] == "Sileo" {
            let originalImage = UIImage(named: "Sileo_logo")
            let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { _ in
                originalImage?.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
            }
            cell.imageView?.image = resizedImage
        } else if tableData[indexPath.section][indexPath.row] == "Zebra" {
            let originalImage = UIImage(named: "Zebra_logo")
            let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { _ in
                originalImage?.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
            }
            cell.imageView?.image = resizedImage
        }
        if tableData[indexPath.section][indexPath.row] == "Utilities" || tableData[indexPath.section][indexPath.row] == "Openers"{
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = .systemOrange
            cell.selectionStyle = .default
        }
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if let revision = Bundle.main.infoDictionary?["REVISION"] as? String {
            if section == tableData.count - 1 {
                return "palera1n Loader lite • 1.0 (\(revision))"
            }
        }
        return nil
    }
    
    // MARK: - Actions action + actions for alertController
    @objc func openersTapped() {
        var alertController = UIAlertController(title: "Open an application", message: nil, preferredStyle: .actionSheet)
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController = UIAlertController(title: "Open an application", message: nil, preferredStyle: .alert)
        }
        
        // Create actions for each app to be opened
        let openSAction = UIAlertAction(title: "Open Sileo", style: .default) { (_) in
            if LSApplicationWorkspace.default().openApplication(withBundleID: "org.coolstar.SileoStore") {
            } else {
                if LSApplicationWorkspace.default().openApplication(withBundleID: "org.coolstar.SileoNightly") {
                    return
                }
            }
        }
        
        let openZAction = UIAlertAction(title: "Open Zebra", style: .default) { (_) in
            if LSApplicationWorkspace.default().openApplication(withBundleID: "xyz.willy.Zebra") {
            }
        }
        
        let openTHAction = UIAlertAction(title: "Open TrollHelper", style: .default) { (_) in
            if LSApplicationWorkspace.default().openApplication(withBundleID: "com.opa334.trollstorepersistencehelper") {
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
        }
        
        alertController.addAction(openSAction)
        alertController.addAction(openZAction)
        alertController.addAction(openTHAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func actionsTapped() {
        var type = "Unknown"
        if rootful {
            type = "Rootful"
        } else if !rootful {
            type = "Rootless"
        }
        
        var installed = "False"
        if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
            installed = "True"
        }
        
        let processInfo = ProcessInfo()
        let systemVersion = processInfo.operatingSystemVersionString
        let arch = String(cString: NXGetLocalArchInfo().pointee.name)
        
        
        var alertController = UIAlertController(title: """
        Type: \(type)
        Installed: \(installed)
        Architecture: \(arch)
        \(systemVersion)
        """, message: nil, preferredStyle: .actionSheet)
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController = UIAlertController(title: """
            Type: \(type)
            Installed: \(installed)
            Architecture: \(arch)
            \(systemVersion)
            """, message: nil, preferredStyle: .alert)
        }
        
        let respringAction = UIAlertAction(title: "Respring", style: .default) { (_) in
            spawn(command: "\(self.inst_prefix)/usr/bin/sbreload", args: [], root: true)
        }
        let softrebootAction = UIAlertAction(title: "Userspace Reboot", style: .default) { (_) in
            spawn(command: "\(self.inst_prefix)/usr/bin/launchctl", args: ["reboot", "userspace"], root: true)
        }
        let uicacheAction = UIAlertAction(title: "UICache", style: .default) { (_) in
            spawn(command: "\(self.inst_prefix)/usr/bin/uicache", args: ["-a"], root: true)
        }
        let daemonAction = UIAlertAction(title: "Launch Daemons", style: .default) { (_) in
            spawn(command: "\(self.inst_prefix)/bin/launchctl", args: ["bootstrap", "system", "/var/jb/Library/LaunchDaemons"], root: true)
        }
        let mountAction = UIAlertAction(title: "Mount Directories", style: .default) { (_) in
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
            spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)
        }
        let enabletweaksAction = UIAlertAction(title: "Enable Tweaks", style: .default) { (_) in
            if self.rootful {
                spawn(command: "/etc/rc.d/substitute-launcher", args: [], root: true)
            } else {
                spawn(command: "/var/jb/usr/libexec/ellekit/loader", args: [], root: true)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
        }
        alertController.addAction(respringAction)
        alertController.addAction(uicacheAction)
        alertController.addAction(daemonAction)
        alertController.addAction(mountAction)
        alertController.addAction(enabletweaksAction)
        alertController.addAction(softrebootAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Main strapping process
    private func deleteFile(file: String) -> Void {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(file)
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    private func downloadFile(file: String, server: String = "https://static.palera.in/rootless") -> Void {
        var downloadAlert: UIAlertController? = nil
        
        deleteFile(file: file)
        
        DispatchQueue.main.async {
            downloadAlert = UIAlertController(title: "Downloading...", message: "File: \(file)", preferredStyle: .alert)
            let downloadIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            downloadIndicator.hidesWhenStopped = true
            downloadIndicator.startAnimating()
            
            downloadAlert?.view.addSubview(downloadIndicator)
            self.present(downloadAlert!, animated: true)
        }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(file)
        let url = URL(string: "\(server)/\(file)")!
        let semaphore = DispatchSemaphore(value: 0)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.downloadTask(with: url) { tempLocalUrl, response, error in
            if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if statusCode != 200 {
                    if server.contains("cdn.nickchan.lol") {
                        DispatchQueue.main.async {
                            downloadAlert?.dismiss(animated: true, completion: nil)
                            let alertController = self.errorAlert(title: "Could not download file", message: "\(error?.localizedDescription ?? "Unknown error")")
                            self.present(alertController, animated: true, completion: nil)
                            NSLog("[palera1n] Could not download file: \(error?.localizedDescription ?? "Unknown error")")
                        }
                        return
                    }
                    self.downloadFile(file: file, server: server.replacingOccurrences(of: "static.palera.in", with: "cdn.nickchan.lol/palera1n/loader/assets"))
                    return
                }
            }
            if let tempLocalUrl = tempLocalUrl, error == nil {
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: fileURL)
                    semaphore.signal()
                    DispatchQueue.main.async {
                        // Dismiss the loading alert controller
                        downloadAlert?.dismiss(animated: true, completion: nil)
                    }
                } catch (let writeError) {
                    DispatchQueue.main.async {
                        downloadAlert?.dismiss(animated: true, completion: nil)
                        let delayTime = DispatchTime.now() + 0.2
                        DispatchQueue.main.asyncAfter(deadline: delayTime) {
                            let alertController = self.errorAlert(title: "Could not copy file to disk", message: "\(writeError)")
                            if let presentedVC = self.presentedViewController {
                                presentedVC.dismiss(animated: true) {
                                    self.present(alertController, animated: true)
                                }
                            } else {
                                self.present(alertController, animated: true)
                            }
                        }
                        NSLog("[palera1n] Could not copy file to disk: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                }
            } else {
                DispatchQueue.main.async {
                    downloadAlert?.dismiss(animated: true, completion: nil)
                    let delayTime = DispatchTime.now() + 0.2
                    DispatchQueue.main.asyncAfter(deadline: delayTime) {
                        let alertController = self.errorAlert(title: "Could not download file", message: "\(error?.localizedDescription ?? "Unknown error")")
                        if let presentedVC = self.presentedViewController {
                            presentedVC.dismiss(animated: true) {
                                self.present(alertController, animated: true)
                            }
                        } else {
                            self.present(alertController, animated: true)
                        }
                    }
                    NSLog("[palera1n] Could not download file: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
            }
        }
        task.resume()
        semaphore.wait()
    }
    
    var InstallSileo = false
    var InstallZebra = false
    
    private func strap() -> Void {
        let alertController = errorAlert(title: "Install Completed", message: "You may close the app.")
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
            let msg = "Could not find helper?"
            print("[palera1n] \(msg)")
            return
        }
        
        let delayTime = DispatchTime.now() + 0.2
        let ret = spawn(command: helper, args: ["-f"], root: true)
        let rootful = ret == 0 ? false : true
        let inst_prefix = rootful ? "/" : "/var/jb"
        
        DispatchQueue.global(qos: .userInitiated).async {
            print("[strap] User initiated strap process...")
            DispatchQueue.global(qos: .utility).async { [self] in
                var debName = ""
                if self.InstallSileo {
                    debName = "sileo.deb"
                }
                if self.InstallZebra {
                    debName = "zebra.deb"
                }
                
                if rootful {
                    downloadFile(file: "bootstrap.tar", server: "https://static.palera.in")
                    downloadFile(file: debName, server: "https://static.palera.in")
                } else {
                    downloadFile(file: "bootstrap.tar")
                    downloadFile(file: debName)
                }
                
                DispatchQueue.main.async {
                    guard let tar = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("bootstrap.tar").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                        let msg = "Failed to find bootstrap"
                        print("[palera1n] \(msg)")
                        return
                    }
                    
                    guard let deb = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(debName).path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                        let msg = "Could not find package manager"
                        print("[palera1n] \(msg)")
                        return
                    }
                    
                    let loadingAlert = UIAlertController(title: nil, message: "Installing...", preferredStyle: .alert)
                    let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
                    loadingIndicator.hidesWhenStopped = true
                    loadingIndicator.startAnimating()
                    self.presentedViewController?.dismiss(animated: true) {
                        loadingAlert.view.addSubview(loadingIndicator)
                        // Installing... Alert
                        self.present(loadingAlert, animated: true) {
                            DispatchQueue.global(qos: .utility).async {
                                spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
                                
                                if rootful {
                                    spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)
                                }
                                
                                let ret = spawn(command: helper, args: ["-i", tar], root: true)
                                
                                spawn(command: "\(inst_prefix)/usr/bin/chmod", args: ["4755", "\(inst_prefix)/usr/bin/sudo"], root: true)
                                spawn(command: "\(inst_prefix)/usr/bin/chown", args: ["root:wheel", "\(inst_prefix)/usr/bin/sudo"], root: true)
                                
                                DispatchQueue.main.async {
                                    if ret != 0 {
                                        loadingAlert.dismiss(animated: true) {
                                            let alertController = self.errorAlert(title: "Error installing bootstrap", message: "Status: \(ret)")
                                            self.present(alertController, animated: true, completion: nil)
                                            print("[strap] Error installing bootstrap. Status: \(ret)")
                                            return
                                        }
                                    }
                                    
                                    DispatchQueue.global(qos: .utility).async {
                                        let ret = spawn(command: "\(inst_prefix)/usr/bin/sh", args: ["\(inst_prefix)/prep_bootstrap.sh"], root: true)
                                        DispatchQueue.main.async {
                                            if ret != 0 {
                                                loadingAlert.dismiss(animated: true) {
                                                    let alertController = self.errorAlert(title: "Error installing bootstrap", message: "Status: \(ret)")
                                                    self.present(alertController, animated: true, completion: nil)
                                                    print("[strap] Error installing bootstrap. Status: \(ret)")
                                                    return
                                                }
                                            }
                                            
                                            DispatchQueue.global(qos: .utility).async {
                                                let ret = spawn(command: "\(inst_prefix)/usr/bin/dpkg", args: ["-i", deb], root: true)
                                                
                                                if !rootful {
                                                    let sourcesFilePath = "/var/jb/etc/apt/sources.list.d/procursus.sources"
                                                    var procursusSources = ""
                                                    
                                                    if UIDevice.current.systemVersion.contains("15") {
                                                        procursusSources = """
                                                        Types: deb
                                                        URIs: https://ellekit.space/
                                                        Suites: ./
                                                        Components:
                                                        
                                                        Types: deb
                                                        URIs: https://repo.palera.in/
                                                        Suites: ./
                                                        Components:
                                                        
                                                        Types: deb
                                                        URIs: https://apt.procurs.us/
                                                        Suites: 1800
                                                        Components: main
                                                        
                                                        """
                                                    } else if UIDevice.current.systemVersion.contains("16") {
                                                        procursusSources = """
                                                        Types: deb
                                                        URIs: https://ellekit.space/
                                                        Suites: ./
                                                        Components:
                                                        
                                                        Types: deb
                                                        URIs: https://repo.palera.in/
                                                        Suites: ./
                                                        Components:
                                                        
                                                        Types: deb
                                                        URIs: https://apt.procurs.us/
                                                        Suites: 1900
                                                        Components: main
                                                        
                                                        """
                                                    }
                                                    
                                                    spawn(command: "/var/jb/bin/sh", args: ["-c", "echo '\(procursusSources)' > \(sourcesFilePath)"], root: true)
                                                } else {
                                                    let sourcesFilePath = "/etc/apt/sources.list.d/procursus.sources"
                                                    var procursusSources = ""
                                                    
                                                    if UIDevice.current.systemVersion.contains("15") {
                                                        procursusSources = """
                                                        Types: deb
                                                        URIs: https://repo.palera.in/
                                                        Suites: ./
                                                        Components:
                                                        
                                                        Types: deb
                                                        URIs: https://strap.palera.in/
                                                        Suites: iphoneos-arm64/1800
                                                        Components: main
                                                        
                                                        """
                                                    } else if UIDevice.current.systemVersion.contains("16") {
                                                        procursusSources = """
                                                        Types: deb
                                                        URIs: https://repo.palera.in/
                                                        Suites: ./
                                                        Components:
                                                        
                                                        Types: deb
                                                        URIs: https://strap.palera.in/
                                                        Suites: iphoneos-arm64/1900
                                                        Components: main
                                                        
                                                        """
                                                    }
                                                    
                                                    spawn(command: "/bin/sh", args: ["-c", "echo '\(procursusSources)' > \(sourcesFilePath)"], root: true)
                                                }
                                                
                                                DispatchQueue.main.async {
                                                    if ret != 0 {
                                                        let alertController = self.errorAlert(title: "Failed to install packages", message: "Status: \(ret)")
                                                        self.present(alertController, animated: true, completion: nil)
                                                        print("[strap] Failed to install packages. Status: \(ret)")
                                                        return
                                                    }
                                                    
                                                    DispatchQueue.global(qos: .utility).async {
                                                        let ret = spawn(command: "\(inst_prefix)/usr/bin/uicache", args: ["-a"], root: true)
                                                        DispatchQueue.main.async {
                                                            if ret != 0 {
                                                                let alertController = self.errorAlert(title: "Failed to uicache", message: "Status: \(ret)")
                                                                self.present(alertController, animated: true, completion: nil)
                                                                print("[strap] Failed to uicache. Status: \(ret)")
                                                                return
                                                            }
                                                        }
                                                    }
                                                }
                                                
                                                DispatchQueue.main.async {
                                                    loadingAlert.dismiss(animated: true) {
                                                        DispatchQueue.main.asyncAfter(deadline: delayTime) {
                                                            self.present(alertController, animated: true)
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    // MARK: - Main table cells
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemTapped = tableData[indexPath.section][indexPath.row]
        switch itemTapped {
        case "Utilities":
            actionsTapped()
        case "Openers":
            openersTapped()
        case "Revert Install":
            var alertController = UIAlertController(title: "Confirm", message: "Wipes /var/jb and unregisters jailbreak applications, after that you will be prompt to close the loader.", preferredStyle: .actionSheet)
            if UIDevice.current.userInterfaceIdiom == .pad {
                alertController = UIAlertController(title: "Confirm", message: "Wipes /var/jb and unregisters jailbreak applications, after that you will be prompt to close the loader.", preferredStyle: .alert)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let confirmAction = UIAlertAction(title: "Revert Install", style: .destructive) { _ in
                self.nuke()
            }
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        case "Sileo":
            if FileManager.default.fileExists(atPath: "/Applications/Sileo.app") || FileManager.default.fileExists(atPath: "/var/jb/Applications/Sileo.app") || FileManager.default.fileExists(atPath: "/var/jb/Applications/Sileo-Nightly.app") || FileManager.default.fileExists(atPath: "/var/jb/Applications/Sileo-Nightly.app") {
                var alertController = UIAlertController(title: "Confirm", message: "Are you sure you want to re-install Sileo?", preferredStyle: .actionSheet)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    alertController = UIAlertController(title: "Confirm", message: "Are you sure you want to re-install Sileo?", preferredStyle: .alert)
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: "Re-install", style: .default) { _ in
                    self.reInstallSileo()
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                var alertController = UIAlertController(title: "Confirm", message: "Are you sure you want to Install Sileo?", preferredStyle: .actionSheet)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    alertController = UIAlertController(title: "Confirm", message: "Are you sure you want to Install Sileo?", preferredStyle: .alert)
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: "Install", style: .default) { _ in
                    self.reInstallSileo()
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else {
                self.InstallSileo = true
                self.strap()
            }
        case "Zebra":
            if FileManager.default.fileExists(atPath: "/Applications/Zebra.app") || FileManager.default.fileExists(atPath: "/var/jb/Applications/Zebra.app") {
                var alertController = UIAlertController(title: "Confirm", message: "Are you sure you want to re-install Zebra?", preferredStyle: .actionSheet)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    alertController = UIAlertController(title: "Confirm", message: "Are you sure you want to re-install Zebra?", preferredStyle: .alert)
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: "Re-install", style: .default) { _ in
                    self.reInstallZebra()
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                var alertController = UIAlertController(title: "Confirm", message: "Are you sure you want to install Zebra?", preferredStyle: .actionSheet)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    alertController = UIAlertController(title: "Confirm", message: "Are you sure you want to install Zebra?", preferredStyle: .alert)
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: "Install", style: .default) { _ in
                    self.reInstallZebra()
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else {
                self.InstallZebra = true
                self.strap()
            }
            
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    // MARK: - Functions for (Re)installing Sileo/Zebra
    func reInstallZebra() {
        let alertController = errorAlert(title: "Install Completed", message: "Enjoy!")
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
            let msg = "Could not find helper?"
            print("[palera1n] \(msg)")
            return
        }
        
        let ret = spawn(command: helper, args: ["-f"], root: true)
        
        let rootful = ret == 0 ? false : true
        
        let inst_prefix = rootful ? "/" : "/var/jb"
        
        print("[strap] Installing Zebra")
        DispatchQueue.global(qos: .utility).async { [self] in
            if rootful {
                downloadFile(file: "zebra.deb", server: "https://static.palera.in")
            } else {
                downloadFile(file: "zebra.deb")
            }
            
            DispatchQueue.global(qos: .utility).async { [self] in
                guard let deb = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("zebra.deb").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                    let alertController = self.errorAlert(title: "Failed to install Zebra", message: "")
                    self.present(alertController, animated: true, completion: nil)
                    print("[strap] Failed to find Zebra.")
                    return
                }
                
                let ret = spawn(command: "\(inst_prefix)/usr/bin/dpkg", args: ["-i", deb], root: true)
                DispatchQueue.main.async {
                    if ret != 0 {
                        let alertController = self.errorAlert(title: "Failed to install Zebra", message: "Status: \(ret)")
                        self.present(alertController, animated: true, completion: nil)
                        print("[strap] Failed to install Zebra. Status: \(ret)")
                        return
                    }
                    let delayTime = DispatchTime.now() + 0.2
                    DispatchQueue.main.asyncAfter(deadline: delayTime) {
                        self.present(alertController, animated: true)
                        print("[strap] Installed Zebra")
                    }
                }
            }
        }
    }
    
    func reInstallSileo() {
        let alertController = errorAlert(title: "Install Completed", message: "Enjoy!")
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
            let msg = "Could not find helper?"
            print("[palera1n] \(msg)")
            return
        }
        
        let ret = spawn(command: helper, args: ["-f"], root: true)
        let rootful = ret == 0 ? false : true
        let inst_prefix = rootful ? "/" : "/var/jb"
        
        print("[strap] Installing Sileo")
        DispatchQueue.global(qos: .utility).async { [self] in
            if rootful {
                downloadFile(file: "sileo.deb", server: "https://static.palera.in")
            } else {
                downloadFile(file: "sileo.deb")
            }
            
            DispatchQueue.global(qos: .utility).async { [self] in
                guard let deb = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("sileo.deb").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                    let alertController = self.errorAlert(title: "Failed to install Sileo", message: "")
                    self.present(alertController, animated: true, completion: nil)
                    print("[strap] Failed to find Sileo.")
                    return
                }
                
                let ret = spawn(command: "\(inst_prefix)/usr/bin/dpkg", args: ["-i", deb], root: true)
                DispatchQueue.main.async {
                    if ret != 0 {
                        let alertController = self.errorAlert(title: "Failed to install Sileo", message: "Status: \(ret)")
                        self.present(alertController, animated: true, completion: nil)
                        print("[strap] Failed to install Sileo. Status: \(ret)")
                        return
                    }
                    let delayTime = DispatchTime.now() + 0.2
                    DispatchQueue.main.asyncAfter(deadline: delayTime) {
                        self.present(alertController, animated: true)
                        print("[strap] Installed Zebra")
                    }
                }
            }
        }
    }
    // MARK: - NUKER!
    func nuke() {
        
        print("[nuke] Starting nuke process...")
        let alertController = errorAlert(title: "Remove Completed", message: "You may close the app.")
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
            let msg = "Could not find helper?"
            print("[palera1n] \(msg)")
            return
        }
        
        let ret = spawn(command: helper, args: ["-f"], root: true)
        let rootful = ret == 0 ? false : true
        if !rootful {
            
            let loadingAlert = UIAlertController(title: nil, message: "Removing...", preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.startAnimating()
            
            loadingAlert.view.addSubview(loadingIndicator)
            print("[nuke] Unregistering applications")
            self.present(loadingAlert, animated: true)
            DispatchQueue.global(qos: .utility).async {
                // remove all jb apps from uicache
                let apps = try? FileManager.default.contentsOfDirectory(atPath: "/var/jb/Applications")
                for app in apps ?? [] {
                    if app.hasSuffix(".app") {
                        let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-u", "/var/jb/Applications/\(app)"], root: true)
                        DispatchQueue.main.async {
                            if ret != 0 {
                                let alertController = self.errorAlert(title: "Failed to unregister \(app)", message: "Status: \(ret)")
                                self.present(alertController, animated: true, completion: nil)
                                print("[nuke] Failed to unregister \(app): \(ret)")
                                return
                            }
                        }
                    }
                }
                
                print("[nuke] Removing Installation...")
                let ret = spawn(command: helper, args: ["-r"], root: true)
                DispatchQueue.main.async {
                    if ret != 0 {
                        let alertController = self.errorAlert(title: "Failed to remove jailbreak", message: "Status: \(ret)")
                        self.present(alertController, animated: true, completion: nil)
                        print("[nuke] Failed to remove jailbreak: \(ret)")
                        return
                    }
                    print("[nuke] Jailbreak removed!")
                    loadingAlert.dismiss(animated: true) {
                        let delayTime = DispatchTime.now() + 0.2
                        DispatchQueue.main.asyncAfter(deadline: delayTime) {
                            self.present(alertController, animated: true)
                        }
                    }
                }
            }
        }
    }
    // MARK: - Main alerts used throughout
    func errorAlert(title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Close", style: .default) { _ in
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // Exit the app
                exit(0)
            }
        })
        return alertController
    }
}
