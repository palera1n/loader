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

    var tableData = [[local("SILEO"), local("ZEBRA")], [local("UTIL_CELL"), local("OPEN_CELL"), local("REVERT_CELL")]]
    let sectionTitles = [local("INSTALL"), local("DEBUG")]
    
    private func deviceCheck() -> Void {
    #if targetEnvironment(simulator)
        print("[palera1n] Running in simulator")
    #else
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
            let alertController = errorAlert(title: "Could not find helper?", message: "If you've sideloaded this loader app unfortunately you aren't able to use this, please jailbreak with palera1n before proceeding.")
            print("[palera1n] Could not find helper?")
            self.present(alertController, animated: true, completion: nil)
            return
        }
        
        let ret = spawn(command: helper, args: ["-f"], root: true)
        print("RET TEST: \(ret)")
        rootful = ret == 0 ? false : true
        inst_prefix = rootful ? "/" : "/var/jb"
        print("ROOTFULL: \(rootful)")
        print("PREIX: \(inst_prefix)")

        let retRFR = spawn(command: helper, args: ["-n"], root: true)
        print("retRFR: \(retRFR)")

        let rfr = retRFR == 0 ? false : true
        print("rfr: \(rfr)")

        if rfr {
            let alertController = ViewController().errorAlert(title: "Unable to continue", message: "Bootstrapping after using --force-revert is not supported, please rejailbreak to be able to bootstrap again.")
            self.present(alertController, animated: true, completion: nil)
            return
        }
    #endif
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (inst_prefix == "unset") { deviceCheck()}
        
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
        
        let discord = UIAction(title: local("DISCORD"), image: UIImage(systemName: "arrow.up.forward.app")) { (_) in
            UIApplication.shared.open(URL(string: "https://discord.gg/palera1n")!)
        }
        let twitter = UIAction(title: local("TWITTER"), image: UIImage(systemName: "arrow.up.forward.app")) { (_) in
            UIApplication.shared.open(URL(string: "https://twitter.com/palera1n")!)
        }
        let website = UIAction(title: local("WEBSITE"), image: UIImage(systemName: "arrow.up.forward.app")) { (_) in
            UIApplication.shared.open(URL(string: "https://palera.in")!)
        }
 
        var type = "Unknown"
        if rootful { type = local("ROOTFUL") }
        else if !rootful { type = local("ROOTLESS") }
        var installed = local("FALSE")
        if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {installed = local("TRUE")}
        let processInfo = ProcessInfo()
        let systemVersion = processInfo.operatingSystemVersionString
        let arch = String(cString: NXGetLocalArchInfo().pointee.name)
        
        let menu = UIMenu(title: "\(local("TYPE_INFO")) \(type)\n\(local("INSTALL_INFO")) \(installed)\n\(local("ARCH_INFO")) \(arch)\n\(systemVersion)", children: [discord, twitter, website])
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "info.circle"), primaryAction: nil, menu: menu)
        
        
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
        
        if tableData[indexPath.section][indexPath.row] == local("REVERT_CELL") {
            if FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                cell.isHidden = false
                cell.isUserInteractionEnabled = true
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.textColor = .systemRed
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped"){
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textColor = .gray
                cell.detailTextLabel?.text = local("REVERT_SUBTEXT")
                cell.selectionStyle = .none
            } else {
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textColor = .gray
                cell.selectionStyle = .none
            }
        } else if tableData[indexPath.section][indexPath.row] == local("SILEO") || tableData[indexPath.section][indexPath.row] == local("ZEBRA") {
            guard Bundle.main.path(forAuxiliaryExecutable: "Helper") != nil else {
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textColor = .gray
                cell.selectionStyle = .default
                return cell
            };
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
//            cell.detailTextLabel?.text = tableData[indexPath.section][indexPath.row] == "Sileo" ? "Modern package manager" : "Familiar looking package manager"
            cell.selectionStyle = .default
        }
        
        if tableData[indexPath.section][indexPath.row] == local("SILEO") {
            let originalImage = UIImage(named: "Sileo_logo")
            let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { _ in
                originalImage?.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
            }
            cell.imageView?.image = resizedImage
        } else if tableData[indexPath.section][indexPath.row] == local("ZEBRA") {
            let originalImage = UIImage(named: "Zebra_logo")
            let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { _ in
                originalImage?.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
            }
            cell.imageView?.image = resizedImage
        }
        if tableData[indexPath.section][indexPath.row] == local("UTIL_CELL") || tableData[indexPath.section][indexPath.row] == local("OPEN_CELL"){
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = UIColor(red: 0.89, green: 0.52, blue: 0.43, alpha: 1.00)
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
                return "universal_lite • 1.0 (\(revision))"
            } else if section == 0 {
                return local("PM_SUBTEXT")
            }
        }
        return nil
    }
    // MARK: - Actions action + actions for alertController

    
    @objc func openersTapped() {
        var alertController = UIAlertController(title: local("OPENER_MSG"), message: nil, preferredStyle: .actionSheet)
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController = UIAlertController(title: local("OPENER_MSG"), message: nil, preferredStyle: .alert)
        }
        
        // Create actions for each app to be opened
        let sileo = UIAlertAction(title: local("OPENER_SILEO"), style: .default) { (_) in
            if (openApp("org.coolstar.SileoStore")){}else{_=openApp("org.coolstar.SileoStore")}}
        let zebra = UIAlertAction(title: local("OPENER_ZEBRA"), style: .default) { (_) in _=openApp("xyz.willy.Zebra")}
        let trollhelper = UIAlertAction(title: local("OPENER_TH"), style: .default) { (_) in _=openApp("com.opa334.trollstorepersistencehelper")}
        
        sileo.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        sileo.setValue(UIImage(systemName: "arrow.up.forward.app"), forKey: "image")
        zebra.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        zebra.setValue(UIImage(systemName: "arrow.up.forward.app"), forKey: "image")
        trollhelper.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        trollhelper.setValue(UIImage(systemName: "arrow.up.forward.app"), forKey: "image")
        alertController.addAction(sileo)
        alertController.addAction(zebra)
        alertController.addAction(trollhelper)
        alertController.addAction(UIAlertAction(title: local("CANCEL"), style: .cancel) { (_) in})
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func actionsTapped() {
        var pre = "/var/jb"
        if rootful { pre = "/"}

        var alertController = UIAlertController(title: local("UTIL_CELL"), message: nil, preferredStyle: .actionSheet)
        if UIDevice.current.userInterfaceIdiom == .pad {
            alertController = UIAlertController(title: local("UTIL_CELL"), message: nil, preferredStyle: .alert)
        }
        let respring = UIAlertAction(title: local("RESPRING"), style: .default) { (_) in
            spawn(command: "\(pre)/usr/bin/sbreload", args: [], root: true)
        }
        let usReboot = UIAlertAction(title: local("US_REBOOT"), style: .default) { (_) in
            spawn(command: "\(pre)/usr/bin/launchctl", args: ["reboot", "userspace"], root: true)
        }
        let uicache = UIAlertAction(title: local("UICACHE"), style: .default) { (_) in
            spawn(command: "\(pre)/usr/bin/uicache", args: ["-a"], root: true)
        }
        let daemons = UIAlertAction(title: local("DAEMONS"), style: .default) { (_) in
            spawn(command: "\(pre)/bin/launchctl", args: ["bootstrap", "system", "/var/jb/Library/LaunchDaemons"], root: true)
        }
        let mount = UIAlertAction(title: local("MOUNT"), style: .default) { (_) in
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
            spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)
        }
        let tweaks = UIAlertAction(title: local("TWEAKS"), style: .default) { (_) in
            if self.rootful {spawn(command: "/etc/rc.d/substitute-launcher", args: [], root: true)}
            else {spawn(command: "/var/jb/usr/libexec/ellekit/loader", args: [], root: true)}
        }
        respring.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        usReboot.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        uicache.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        daemons.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        mount.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        tweaks.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
        respring.setValue(UIImage(systemName: "arrow.clockwise.circle"), forKey: "image")
        usReboot.setValue(UIImage(systemName: "power.circle"), forKey: "image")
        uicache.setValue(UIImage(systemName: "xmark.circle"), forKey: "image")
        daemons.setValue(UIImage(systemName: "play.circle"), forKey: "image")
        mount.setValue(UIImage(systemName: "folder.circle"), forKey: "image")
        tweaks.setValue(UIImage(systemName: "iphone.circle"), forKey: "image")

        alertController.addAction(respring)
        alertController.addAction(usReboot)
        alertController.addAction(uicache)
        alertController.addAction(daemons)
        alertController.addAction(mount)
        alertController.addAction(tweaks)

        alertController.addAction(UIAlertAction(title: local("CANCEL"), style: .cancel) { (_) in})
        present(alertController, animated: true, completion: nil)
    }
    

    // MARK: - Main strapping process
     func deleteFile(file: String) -> Void {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(file)
        try? FileManager.default.removeItem(at: fileURL)
    }

     func downloadFile(file: String, server: String = "https://static.palera.in/rootless") -> Void {
        var downloadAlert: UIAlertController? = nil
        
        deleteFile(file: file)
        
        DispatchQueue.main.async {
            downloadAlert = UIAlertController(title: local("DOWNLOADING"), message: "File: \(file)", preferredStyle: .alert)
            let downloadIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 15, width: 50, height: 50))
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
                            let alertController = self.errorAlert(title: local("DOWNLOAD_FAIL"), message: "\(error?.localizedDescription ?? local("DOWNLOAD_ERROR"))")
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
                            let alertController = self.errorAlert(title: local("SAVE_FAIL"), message: "\(writeError)")
                            if let presentedVC = self.presentedViewController {
                                presentedVC.dismiss(animated: true) {self.present(alertController, animated: true)}
                            } else {self.present(alertController, animated: true)}
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
                        let alertController = self.errorAlert(title: local("DOWNLOAD_FAIL"), message: "\(error?.localizedDescription ?? local("DOWNLOAD_ERROR"))")
                        if let presentedVC = self.presentedViewController {
                            presentedVC.dismiss(animated: true) {self.present(alertController, animated: true)}
                        } else {self.present(alertController, animated: true)}
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

     func strap() -> Void {
        let alertController = errorAlert(title: local("INSTALL_DONE"), message: local("INSTALL_DONE_SUB"))
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
                if self.InstallSileo { debName = "sileo.deb" }
                if self.InstallZebra { debName = "zebra.deb" }
                
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
                        print("[palera1n] \(msg)")    // MARK: - Main strapping process
                        return
                    }
                    
                    let loadingAlert = UIAlertController(title: nil, message: local("INSTALLING"), preferredStyle: .alert)
                    let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
                    loadingIndicator.hidesWhenStopped = true
                    loadingIndicator.startAnimating()
                    self.presentedViewController?.dismiss(animated: true) {
                        loadingAlert.view.addSubview(loadingIndicator)
                        // Installing... Alert
                        self.present(loadingAlert, animated: true) {
                            DispatchQueue.global(qos: .utility).async {
                                spawn(command: "/sbin/mount", args: ["-uw", "//preboot"], root: true)
                                if rootful { spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)}
                                let ret = spawn(command: helper, args: ["-i", tar], root: true)
                                spawn(command: "\(inst_prefix)/usr/bin/chmod", args: ["4755", "\(inst_prefix)/usr/bin/sudo"], root: true)
                                spawn(command: "\(inst_prefix)/usr/bin/chown", args: ["root:wheel", "\(inst_prefix)/usr/bin/sudo"], root: true)
                                
                                DispatchQueue.main.async {
                                    if ret != 0 {
                                        loadingAlert.dismiss(animated: true) {
                                            let alertController = self.errorAlert(title: local("STRAP_ERROR"), message: "Status: \(ret)")
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
                                                    let alertController = self.errorAlert(title: local("STRAP_ERROR"), message: "Status: \(ret)")
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
                                                        let alertController = self.errorAlert(title: local("DPKG_ERROR"), message: "Status: \(ret)")
                                                        self.present(alertController, animated: true, completion: nil)
                                                        print("[strap] Failed to install packages. Status: \(ret)")
                                                        return
                                                    }
                                                    
                                                    DispatchQueue.global(qos: .utility).async {
                                                        let ret = spawn(command: "\(inst_prefix)/usr/bin/uicache", args: ["-a"], root: true)
                                                        DispatchQueue.main.async {
                                                            if ret != 0 {
                                                                let alertController = self.errorAlert(title: local("UICACHE_ERROR"), message: "Status: \(ret)")
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
        case local("UTIL_CELL"):
            actionsTapped()
        case local("OPEN_CELL"):
            openersTapped()
        case local("REVERT_CELL"):
            var alertController = UIAlertController(title: local("CONFIRM"), message: local("REVERT_WARNING"), preferredStyle: .actionSheet)
            if UIDevice.current.userInterfaceIdiom == .pad {
                alertController = UIAlertController(title: local("CONFIRM"), message: local("REVERT_WARNING"), preferredStyle: .alert)
            }
            let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
            let confirmAction = UIAlertAction(title: local("REVERT_CELL"), style: .destructive) { _ in
                self.nuke()
            }
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        case local("SILEO"):
            if FileManager.default.fileExists(atPath: "/Applications/Sileo.app") || FileManager.default.fileExists(atPath: "/var/jb/Applications/Sileo.app") || FileManager.default.fileExists(atPath: "/var/jb/Applications/Sileo-Nightly.app") || FileManager.default.fileExists(atPath: "/var/jb/Applications/Sileo-Nightly.app") {
                var alertController = UIAlertController(title: local("CONFIRM"), message: local("SILEO_REINSTALL"), preferredStyle: .actionSheet)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    alertController = UIAlertController(title: local("CONFIRM"), message: local("SILEO_REINSTALL"), preferredStyle: .alert)
                }
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("REINSTALL"), style: .default) { _ in
                    self.reInstallSileo()
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                var alertController = UIAlertController(title: local("CONFIRM"), message: local("SILEO_REINSTALL"), preferredStyle: .actionSheet)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    alertController = UIAlertController(title: local("CONFIRM"), message: local("SILEO_REINSTALL"), preferredStyle: .alert)
                }
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("REINSTALL"), style: .default) { _ in
                    self.reInstallSileo()
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else {
                self.InstallSileo = true
                self.strap()
            }
        case local("ZEBRA"):
            if FileManager.default.fileExists(atPath: "/Applications/Zebra.app") || FileManager.default.fileExists(atPath: "/var/jb/Applications/Zebra.app") {
                var alertController = UIAlertController(title: local("CONFIRM"), message: local("ZEBRA_REINSTALL"), preferredStyle: .actionSheet)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    alertController = UIAlertController(title: local("CONFIRM"), message: local("ZEBRA_REINSTALL"), preferredStyle: .alert)
                }
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("REINSTALL"), style: .default) { _ in
                    self.reInstallZebra()
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                var alertController = UIAlertController(title: local("CONFIRM"), message: local("ZEBRA_REINSTALL"), preferredStyle: .actionSheet)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    alertController = UIAlertController(title: local("CONFIRM"), message: local("ZEBRA_REINSTALL"), preferredStyle: .alert)
                }
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("REINSTALL"), style: .default) { _ in
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
        var installingAlert: UIAlertController? = nil
        let alertController = errorAlert(title: local("INSTALL_DONE"), message: local("ENJOY"))
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
            
            DispatchQueue.main.async {
                installingAlert = UIAlertController(title: local("INSTALLING"), message: nil, preferredStyle: .alert)
                let installingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
                installingIndicator.hidesWhenStopped = true
                installingIndicator.startAnimating()
                
                installingAlert?.view.addSubview(installingIndicator)
                self.present(installingAlert!, animated: true)
            }
            
            DispatchQueue.global(qos: .utility).async { [self] in
                guard let deb = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("zebra.deb").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                    installingAlert?.dismiss(animated: true, completion: nil)
                    let alertController = self.errorAlert(title: local("ZEBRA_FAIL"), message: "")
                    self.present(alertController, animated: true, completion: nil)
                    print("[strap] Failed to find Zebra.")
                    return
                }
                
                let ret = spawn(command: "\(inst_prefix)/usr/bin/dpkg", args: ["-i", deb], root: true)
                DispatchQueue.main.async {
                    if ret != 0 {
                        installingAlert?.dismiss(animated: true, completion: nil)
                        let alertController = self.errorAlert(title: local("ZEBRA_FAIL"), message: "Status: \(ret)")
                        self.present(alertController, animated: true, completion: nil)
                        print("[strap] Failed to install Zebra. Status: \(ret)")
                        return
                    }
                    let delayTime = DispatchTime.now() + 0.2
                    DispatchQueue.main.asyncAfter(deadline: delayTime) {
                        installingAlert?.dismiss(animated: true, completion: nil)
                        self.present(alertController, animated: true)
                        print("[strap] Installed Zebra")
                    }
                }
            }
        }
    }
    
    func reInstallSileo() {
        var installingAlert: UIAlertController? = nil
        let alertController = errorAlert(title: local("INSTALL_DONE"), message: local("ENJOY"))
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
            
            DispatchQueue.main.async {
                installingAlert = UIAlertController(title: local("INSTALLING"), message: nil, preferredStyle: .alert)
                let installingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
                installingIndicator.hidesWhenStopped = true
                installingIndicator.startAnimating()
                installingAlert?.view.addSubview(installingIndicator)
                self.present(installingAlert!, animated: true)
            }
            
            DispatchQueue.global(qos: .utility).async { [self] in
                guard let deb = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("sileo.deb").path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                    installingAlert?.dismiss(animated: true, completion: nil)
                    let alertController = self.errorAlert(title: local("SILEO_FAIL"), message: "")
                    self.present(alertController, animated: true, completion: nil)
                    print("[strap] Failed to find Sileo.")
                    return
                }
                
                let ret = spawn(command: "\(inst_prefix)/usr/bin/dpkg", args: ["-i", deb], root: true)
                DispatchQueue.main.async {
                    if ret != 0 {
                        installingAlert?.dismiss(animated: true, completion: nil)
                        let alertController = self.errorAlert(title: local("SILEO_FAIL"), message: "Status: \(ret)")
                        self.present(alertController, animated: true, completion: nil)
                        print("[strap] Failed to install Sileo. Status: \(ret)")
                        return
                    }
                    let delayTime = DispatchTime.now() + 0.2
                    DispatchQueue.main.asyncAfter(deadline: delayTime) {
                        installingAlert?.dismiss(animated: true, completion: nil)
                        self.present(alertController, animated: true)
                        print("[strap] Installed Sileo")
                    }
                }
            }
        }
    }
    // MARK: - NUKER!
    func nuke() {
        
        print("[nuke] Starting nuke process...")
        let alertController = errorAlert(title: local("REVERT_DONE"), message: local("CLOSE_APP"))
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
                        let alertController = self.errorAlert(title: local("REVERT_FAIL"), message: "Status: \(ret)")
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
        alertController.addAction(UIAlertAction(title: local("CLOSE"), style: .default) { _ in
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // Exit the app
                exit(0)
            }
        })
        return alertController
    }
}
