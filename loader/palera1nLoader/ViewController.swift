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

var rootful : Bool = false
var inst_prefix: String = "unset"


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    func deviceCheck() -> Void {
        #if targetEnvironment(simulator)
        print("[palera1n] Running in simulator")
        #else
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
            errAlert(title: "Could not find helper?", message: "If you've sideloaded this loader app unfortunately you aren't able to use this, please jailbreak with palera1n before proceeding.")
            return
        }
        
        let ret = spawn(command: helper, args: ["-f"], root: true)
        rootful = ret == 0 ? false : true
        inst_prefix = rootful ? "/" : "/var/jb"
        let retRFR = spawn(command: helper, args: ["-n"], root: true)
        let rfr = retRFR == 0 ? false : true
        if rootful {
            if rfr {
                errAlert(title: "Unable to continue", message: "Bootstrapping after using --force-revert is not supported, please rejailbreak to be able to bootstrap again.")
                return
            }
        }
        #endif
    }
    var observation: NSKeyValueObservation?
    let progressDownload : UIProgressView = UIProgressView(progressViewStyle: .default)
    var rebootAfter: Bool = true
    var tableData = [[local("SILEO"), local("ZEBRA")], [local("UTIL_CELL"), local("OPEN_CELL"), local("REVERT_CELL")]]
    let sectionTitles = [local("INSTALL"), local("DEBUG")]

    override func viewDidLoad() {
        super.viewDidLoad()
        if (inst_prefix == "unset") { deviceCheck()}
        
        let appearance = UINavigationBarAppearance()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance

        let customView: UIView = {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
            view.translatesAutoresizingMaskIntoConstraints = false
            
            let button: UIButton = {
                let button = UIButton(type: .custom)
                button.translatesAutoresizingMaskIntoConstraints = false
                button.widthAnchor.constraint(equalToConstant: 25).isActive = true
                button.heightAnchor.constraint(equalToConstant: 25).isActive = true
                button.layer.cornerRadius = 6
                button.clipsToBounds = true
                button.setBackgroundImage(UIImage(named: "AppIcon"), for: .normal)
                button.layer.borderWidth = 0.7
                button.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
                return button
            }()
            view.addSubview(button)
            
            let titleLabel: UILabel = {
                let label = UILabel()
                label.translatesAutoresizingMaskIntoConstraints = false
                label.text = "palera1n"
                label.font = UIFont.boldSystemFont(ofSize: 17)
                return label
            }()
            view.addSubview(titleLabel)
            
            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                button.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                titleLabel.leadingAnchor.constraint(equalTo: button.trailingAnchor, constant: 8),
                titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
            
            return view
        }()

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
        let systemVersion = "\(local("VERSION_INFO")) \(UIDevice.current.systemVersion)"
        let arch = String(cString: NXGetLocalArchInfo().pointee.name)
        let menu = UIMenu(title: "\(local("TYPE_INFO")) \(type)\n\(local("INSTALL_INFO")) \(installed)\n\(local("ARCH_INFO")) \(arch)\n\(systemVersion)", children: [discord, twitter, website])
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "info.circle"), primaryAction: nil, menu: menu)
        navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: customView)]
        let tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)        
    }
    
    func spinnerAlert(_ str: String.LocalizationValue) {
        DispatchQueue.main.async {
            let loadingAlert = UIAlertController(title: nil, message: local(str), preferredStyle: .alert)
            if (str != "INSTALLING" && str != "REMOVING") {
                let constraintHeight = NSLayoutConstraint(
                    item: loadingAlert.view!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute:
                        NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 75)
                loadingAlert.view.addConstraint(constraintHeight)
                self.progressDownload.setProgress(0.0/1.0, animated: true)
                self.progressDownload.frame = CGRect(x: 25, y: 55, width: 220, height: 0)
                loadingAlert.view.addSubview(self.progressDownload)
            } else {
                let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
                loadingAlert.view.addSubview(loadingIndicator)
                loadingIndicator.hidesWhenStopped = true
                loadingIndicator.startAnimating()
            }
            self.present(loadingAlert, animated: true, completion: nil)
        }
    }
    
    func closeAllAlerts() {
        if (self.presentedViewController != nil) {
            DispatchQueue.main.async {self.presentedViewController!.dismiss(animated: true)}
        }
    }

    func errAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: local("CLOSE"), style: .default) { _ in
                cleanUp()
                UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { exit(0) }
            })
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData[section].count
    }
    
    
    // MARK: - Viewtable for Sileo/Zebra/Revert/Etc
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.imageView?.layer.cornerRadius = 7
        cell.imageView?.clipsToBounds = true
        cell.imageView?.layer.borderWidth = 1
        cell.imageView?.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
        cell.textLabel?.text = tableData[indexPath.section][indexPath.row]

        switch tableData[indexPath.section][indexPath.row] {
        case local("REVERT_CELL"):
            if FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                cell.isHidden = false
                cell.isUserInteractionEnabled = true
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.textColor = UIColor(red: 0.90, green: 0.29, blue: 0.29, alpha: 1.00)
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
        case local("SILEO"):
            let originalImage = UIImage(named: "Sileo_logo")
            let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { _ in
                originalImage?.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
            }
            cell.imageView?.image = resizedImage
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
            cell.selectionStyle = .default
        case local("ZEBRA"):
            let originalImage = UIImage(named: "Zebra_logo")
            let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { context in
                originalImage?.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30), blendMode: .normal, alpha: 0.5)
            }
            cell.imageView?.image = resizedImage
            cell.isUserInteractionEnabled = false
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = .gray
            cell.selectionStyle = .none
        case local("UTIL_CELL"), local("OPEN_CELL"):
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = UIColor(red: 0.89, green: 0.52, blue: 0.43, alpha: 1.00)
            cell.selectionStyle = .default
        default:
            break
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
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let installed = FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped")
        if (indexPath.section == 1 && indexPath.row == 2 && !rootful && installed) {
            return UIContextMenuConfiguration(previewProvider: nil) { [self] _ in
                let doReboot = UIAction(title: "Reboot after revert", image: UIImage(systemName: "power.circle"), state: rebootAfter ? .on : .off ) { _ in
                    if(!self.rebootAfter){self.rebootAfter = true}else{self.rebootAfter = false}
                }
                return UIMenu(title: "", image: nil, identifier: .none, options: .singleSelection, children: [doReboot])
            }
        }
        return nil
    }


    // MARK: - Actions 'open app' + 'utilities' for alertController
    @objc func openersTapped() {
        let alertController = whichAlert(title: local("OPENER_MSG"))
        let actions: [(title: String, imageName: String, handler: () -> Void)] = [
            (title: local("OPENER_SILEO"), imageName: "arrow.up.forward.app", handler: {
                if (openApp("org.coolstar.SileoStore")){}else{_ = openApp("org.coolstar.SileoNightly")}
            }),
            (title: local("OPENER_ZEBRA"), imageName: "arrow.up.forward.app", handler: { _ = openApp("xyz.willy.Zebra")}),
            (title: local("OPENER_TH"), imageName: "arrow.up.forward.app", handler: { _ = openApp("com.opa334.trollstorepersistencehelper")})
        ]
        
        for action in actions {
            let alertAction = UIAlertAction(title: action.title, style: .default) { (_) in action.handler() }
            alertAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            if let image = UIImage(systemName: action.imageName) { alertAction.setValue(image, forKey: "image") }
            alertController.addAction(alertAction)
        }
        
        alertController.addAction(UIAlertAction(title: local("CANCEL"), style: .cancel) { (_) in})
        present(alertController, animated: true, completion: nil)
    }
    
    
    @objc func actionsTapped() {
        var pre = "/var/jb"
        if rootful { pre = "/"}
        let alertController = whichAlert(title: local("UTIL_CELL"))

        let actions: [(title: String, imageName: String, handler: () -> Void)] = [
            (title: local("RESPRING"), imageName: "arrow.clockwise.circle", handler: { spawn(command: "\(pre)/usr/bin/sbreload", args: [], root: true)}),
            (title: local("US_REBOOT"), imageName: "power.circle", handler: { spawn(command: "\(pre)/usr/bin/launchctl", args: ["reboot", "userspace"], root: true)}),
            (title: local("UICACHE"), imageName: "xmark.circle", handler: { spawn(command: "\(pre)/usr/bin/uicache", args: ["-a"], root: true)}),
            (title: local("DAEMONS"), imageName: "play.circle", handler: { spawn(command: "\(pre)/bin/launchctl", args: ["bootstrap", "system", "/var/jb/Library/LaunchDaemons"], root: true)}),
            (title: local("MOUNT"), imageName: "folder.circle", handler: { spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true); spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true) }),
            (title: local("TWEAKS"), imageName: "iphone.circle", handler: {
                if rootful {spawn(command: "/etc/rc.d/substitute-launcher", args: [], root: true)}
                else {spawn(command: "/var/jb/usr/libexec/ellekit/loader", args: [], root: true)}
            })
        ]

        for action in actions {
            let alertAction = UIAlertAction(title: action.title, style: .default) { (_) in action.handler() }
            alertAction.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            if let image = UIImage(systemName: action.imageName) { alertAction.setValue(image, forKey: "image") }
            alertController.addAction(alertAction)
        }

        alertController.addAction(UIAlertAction(title: local("CANCEL"), style: .cancel) { (_) in})
        present(alertController, animated: true, completion: nil)
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
            let alertController = whichAlert(title: local("CONFIRM"), message: local("REVERT_WARNING"))
            let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
            let confirmAction = UIAlertAction(title: local("REVERT_CELL"), style: .destructive) {_ in self.revert(self.rebootAfter) }
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        case local("SILEO"):
            let sileoInstalled = UIApplication.shared.canOpenURL(URL(string: "sileo://")!)
            if (sileoInstalled) {
                let alertController = whichAlert(title: local("CONFIRM"), message: local("SILEO_REINSTALL"))
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("REINSTALL"), style: .default) { _ in
                    DispatchQueue.global(qos: .default).async { self.installDeb("sileo", rootful) }
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                let alertController = whichAlert(title: local("CONFIRM"), message: local("SILEO_INSTALL"))
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("INSTALL"), style: .default) { _ in
                    DispatchQueue.global(qos: .default).async { self.installDeb("sileo", rootful) }
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else {
                DispatchQueue.global(qos: .userInitiated).async {
                    print("[strap] User initiated strap process...")
                    self.bootstrap("sileo", rootful)
                }
            }
        case local("ZEBRA"):
            let zebraInstalled = UIApplication.shared.canOpenURL(URL(string: "zbra://")!)
            if (zebraInstalled) {
                let alertController = whichAlert(title: local("CONFIRM"), message: local("ZEBRA_REINSTALL"))
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("REINSTALL"), style: .default) { _ in
                    DispatchQueue.global(qos: .default).async { self.installDeb("zebra", rootful) }
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                let alertController = whichAlert(title: local("CONFIRM"), message: local("ZEBRA_INSTALL"))
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("INSTALL"), style: .default) { _ in
                    DispatchQueue.global(qos: .default).async { self.installDeb("zebra", rootful) }
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else {
                DispatchQueue.global(qos: .userInitiated).async {
                    print("[strap] User initiated strap process...")
                    self.bootstrap("zebra", rootful)
                }
            }
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func download(_ file: String,_ rootful: Bool) -> Void {
        deleteFile(file: file)
        let CF = Int(floor(kCFCoreFoundationVersionNumber / 100) * 100)
        let server = rootful == true ? "https://static.palera.in" : "https://static.palera.in/rootless"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(file)
        var url = URL(string: "\(server)/\(file)")!
        if (file == "bootstrap.tar" && !rootful) {url = URL(string: "\(server)/bootstrap-\(CF).tar")!}
        let semaphore = DispatchSemaphore(value: 0)
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.downloadTask(with: url) { tempLocalUrl, response, error in
            if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                if statusCode != 200 {
                    if server.contains("cdn.nickchan.lol") {
                        self.presentedViewController?.dismiss(animated: true) {
                            self.errAlert(title: local("DOWNLOAD_FAIL"), message: "\(error?.localizedDescription ?? local("DOWNLOAD_ERROR"))")
                            NSLog("[palera1n] Could not download file: \(error?.localizedDescription ?? "Unknown error")");return
                        }
                    };return
                }
            }
            if let tempLocalUrl = tempLocalUrl, error == nil {
                do {
                    try FileManager.default.copyItem(at: tempLocalUrl, to: fileURL)
                    semaphore.signal()
                } catch (let writeError) {
                    self.presentedViewController?.dismiss(animated: true) {
                        self.errAlert(title: local("SAVE_FAIL"), message: "\(writeError)")
                        NSLog("[palera1n] Could not copy file to disk: \(error?.localizedDescription ?? "Unknown error")");return
                    }
                }
            } else {
                self.presentedViewController?.dismiss(animated: true) {
                    self.errAlert(title: local("DOWNLOAD_FAIL"), message: "\(error?.localizedDescription ?? local("DOWNLOAD_ERROR"))")
                    NSLog("[palera1n] Could not download file: \(error?.localizedDescription ?? "Unknown error")");return
                }
            }
        }
        observation = task.progress.observe(\.fractionCompleted) { progress, _ in
            print("progress: ", progress.fractionCompleted)
            DispatchQueue.main.async {
                if (file == "bootstrap.tar") {
                    self.progressDownload.setProgress(Float(progress.fractionCompleted/1.0), animated: true)
                }
            }
        }
        task.resume()
        semaphore.wait()
    }
    
    func installDeb(_ file: String,_ rootful: Bool) -> Void {
        spinnerAlert("INSTALLING")
        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .default).async {
            self.download("\(file).deb", rootful)
            group.leave()
        }
        group.wait()
        let inst_prefix = rootful ? "" : "/var/jb"
        let deb = "\(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(file).deb").path)" // gross
        
        var ret = spawn(command: "\(inst_prefix)/usr/bin/dpkg", args: ["-i", deb], root: true)
        if (ret != 0) {
            self.closeAllAlerts()
            errAlert(title: local("DPKG_ERROR"), message: "Status: \(ret)")
            return
        }
        
        ret = spawn(command: "\(inst_prefix)/usr/bin/uicache", args: ["-a"], root: true)
        if (ret != 0) {
            self.closeAllAlerts()
            errAlert(title: local("UICACHE_ERROR"), message: "Status: \(ret)")
            return
            
        }
        defaultSources(file, rootful)
        self.closeAllAlerts()
        errAlert(title: local("INSTALL_DONE"), message: local("ENJOY"))
    }
            
    func bootstrap(_ pm: String,_ rootful: Bool) -> Void {
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
            print("[palera1n] Could not find helper?")
            return
        }
        if (!rootful && FileManager.default.fileExists(atPath: "/var/jb")) {
            let ret = spawn(command: helper, args: ["-r"], root: true)
            if (ret != 0) {
                self.closeAllAlerts()
                errAlert(title: local("STRAP_ERROR"), message: "Status: \(ret)")
                return
            }
        }
        let inst_prefix = rootful ? "/" : "/var/jb"
        let tar = docsFile(file: "bootstrap.tar")
        let deb = docsFile(file: "\(pm).deb")

        let group = DispatchGroup()
        group.enter()
        DispatchQueue.global(qos: .default).async {
            self.spinnerAlert("DOWNLOADING")
            self.download("bootstrap.tar", rootful)
            self.download("\(pm).deb", rootful)
            self.closeAllAlerts()
            group.leave()
        }
        group.wait()
        
        spinnerAlert("INSTALLING")
        spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
        if rootful { spawn(command: "/sbin/mount", args: ["-uw", "/"], root: true)}
        var ret = spawn(command: helper, args: ["-i", tar], root: true)
        spawn(command: "\(inst_prefix)/usr/bin/chmod", args: ["4755", "\(inst_prefix)/usr/bin/sudo"], root: true)
        spawn(command: "\(inst_prefix)/usr/bin/chown", args: ["root:wheel", "\(inst_prefix)/usr/bin/sudo"], root: true)
        
        if (ret != 0) {
            self.closeAllAlerts()
            errAlert(title: local("STRAP_ERROR"), message: "Status: \(ret)")
            return
        }
        
        ret = spawn(command: "\(inst_prefix)/usr/bin/sh", args: ["\(inst_prefix)/prep_bootstrap.sh"], root: true)
        if (ret != 0) {
            self.closeAllAlerts()
            errAlert(title: local("STRAP_ERROR"), message: "Status: \(ret)")
            return
        }
        
        ret = spawn(command: "\(inst_prefix)/usr/bin/dpkg", args: ["-i", deb], root: true)
        if (ret != 0) {
            self.closeAllAlerts()
            errAlert(title: local("DPKG_ERROR"), message: "Status: \(ret)")
            return
        }
        
        ret = spawn(command: "\(inst_prefix)/usr/bin/uicache", args: ["-a"], root: true)
        if (ret != 0) {
            self.closeAllAlerts()
            errAlert(title: local("UICACHE_ERROR"), message: "Status: \(ret)")
            return
        }
        defaultSources(pm, rootful)
        self.closeAllAlerts()
        errAlert(title: local("INSTALL_DONE"), message: local("ENJOY"))
    }

    
    func revert(_ reboot: Bool) -> Void {
        guard let helper = Bundle.main.path(forAuxiliaryExecutable: "Helper") else {
            print("[palera1n] Could not find helper?");return
        }
        
        let ret = spawn(command: helper, args: ["-f"], root: true)
        let rootful = ret == 0 ? false : true
        if !rootful {
            spawn(command: "/sbin/mount", args: ["-uw", "/private/preboot"], root: true)
            spinnerAlert("REMOVING")
            DispatchQueue.global(qos: .utility).async {
                let apps = try? FileManager.default.contentsOfDirectory(atPath: "/var/jb/Applications")
                for app in apps ?? [] {
                    if app.hasSuffix(".app") {
                        let ret = spawn(command: "/var/jb/usr/bin/uicache", args: ["-u", "/var/jb/Applications/\(app)"], root: true)
                        if ret != 0 {self.errAlert(title: "Failed to unregister \(app)", message: "Status: \(ret)"); return}
                    }
                }
                
                let ret = spawn(command: helper, args: ["-r"], root: true)
                if ret != 0 {
                    self.errAlert(title: local("REVERT_FAIL"), message: "Status: \(ret)")
                    print("[revert] Failed to remove jailbreak: \(ret)")
                    return
                }
                    
                if (reboot) {
                    spawn(command: helper, args: ["-d"], root: true)
                } else {
                    self.closeAllAlerts()
                    self.errAlert(title: local("REVERT_DONE"), message: local("CLOSE_APP"))
                }
            }
        }
    }
}
