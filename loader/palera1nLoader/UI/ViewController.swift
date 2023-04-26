//
//  ViewController.swift
//  pockiiau
//
//  Created by samiiau on 2/27/23.
//  Copyright © 2023 samiiau. All rights reserved.
//

import UIKit
import CoreServices

var observation: NSKeyValueObservation?
var progressDownload: UIProgressView = UIProgressView(progressViewStyle: .default)

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var tableData = [
        [local("SILEO"), local("ZEBRA")],
        [local("ACTIONS"), local("DIAGNOSTICS"), local("JBINIT_LOG"), local("REVERT_CELL")]
    ]
    
    let sectionTitles = [local("INSTALL"), local("DEBUG")]
    
    func downloadFile(url: URL, forceBar: Bool = false, completion: @escaping (String?, Error?) -> Void) {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationUrl = documentsUrl.appendingPathComponent(url.lastPathComponent)

        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            if error == nil {
                if let response = response as? HTTPURLResponse {
                    if response.statusCode == 200 {
                        if let data = data {
                            if let _ = try? data.write(to: destinationUrl, options: Data.WritingOptions.atomic) {
                                completion(destinationUrl.path, error)
                            } else {
                                completion(destinationUrl.path, error)
                            }
                        } else {
                            completion(destinationUrl.path, error)
                        }
                    }
                }
            } else {
                completion(destinationUrl.path, error) // unknown error
            }
        })
        
        if (url.pathExtension == "tar" || forceBar) {
            observation = task.progress.observe(\.fractionCompleted) { progress, _ in
                DispatchQueue.main.async {
                    progressDownload.setProgress(Float(progress.fractionCompleted/1.0), animated: true)
                }
            }
        }

        task.resume()
    }

    func installDebFile(file: String) {
        if (envInfo.isSimulator) {
            return
        }
        
        UIApplication.shared.isIdleTimerDisabled = true
        let title: String.LocalizationValue = file == "sileo.deb" ? "DL_SILEO" : "DL_ZEBRA"
        let downloadAlert = UIAlertController.downloading(title)
        present(downloadAlert, animated: true)
        
        let server = envInfo.isRootful ? URL(string: "https://static.palera.in")! : URL(string: "https://static.palera.in/rootless")!
        let downloadUrl = server.appendingPathComponent(file)
        deleteFile(file: file)
        
        downloadFile(url: downloadUrl, forceBar: true, completion:{(path:String?, error:Error?) in
            DispatchQueue.main.async {
                downloadAlert.dismiss(animated: true) {
                    if (error == nil) {
                        let installingAlert = UIAlertController.spinnerAlert("INSTALLING")
                        self.present(installingAlert, animated: true) {
                            bootstrap().installDebian(deb: path!, withStrap: true, completion:{(msg:String?, error:Int?) in
                                installingAlert.dismiss(animated: true) {
                                    if (error == 0) {
                                        let alert = UIAlertController.error(title: local("INSTALL_DONE"), message: local("INSTALL_DONE_SUB"))
                                        self.present(alert, animated: true)
                                    } else {
                                        let alert = UIAlertController.error(title: local("INSTALL_FAIL"), message: "Status: \(error!)")
                                        self.present(alert, animated: true)
                                    }
                                }
                            })
                        }
                    } else {
                        let alert = UIAlertController.error(title: "Download Failed", message: error!.localizedDescription)
                        self.present(alert, animated: true)
                    }
                }
            }
        })
    }
    
    func installStrap(file: String, completion: @escaping () -> Void) {
        if (envInfo.isSimulator) {
            completion()
            return
        }
        
        UIApplication.shared.isIdleTimerDisabled = true
        let downloadAlert = UIAlertController.downloading("DL_STRAP")
        present(downloadAlert, animated: true)

        let CF = Int(floor(kCFCoreFoundationVersionNumber / 100) * 100)
        let server = envInfo.isRootful ? URL(string: "https://static.palera.in")! : URL(string: "https://static.palera.in/rootless")!
        let downloadUrl: URL?
        let pmUrl: URL?
        let libkrw0Url: URL?
        
        deleteFile(file: file)
        
        if (!envInfo.isRootful) {
            downloadUrl = server.appendingPathComponent("bootstrap-\(CF).tar")
            deleteFile(file: "bootstrap-\(CF).tar")
        } else {
            downloadUrl = server.appendingPathComponent("bootstrap.tar")
            deleteFile(file: "bootstrap.tar")
        }
        
        if (!envInfo.isRootful) {
            libkrw0Url = server.appendingPathComponent("libkrw0-tfp0.deb")
            downloadFile(url: libkrw0Url!, completion:{(path:String?, error:Error?) in})
        }
        pmUrl = server.appendingPathComponent(file)
        downloadFile(url: pmUrl!, completion:{(path:String?, error:Error?) in })

        self.downloadFile(url: downloadUrl!, completion:{(path:String?, error:Error?) in
            DispatchQueue.main.async {
                downloadAlert.dismiss(animated: true) {
                    if (error == nil) {
                        let installingAlert = UIAlertController.spinnerAlert("INSTALLING")
                        self.present(installingAlert, animated: true) {
                            bootstrap().installBootstrap(tar: path!, deb: file, completion:{(msg:String?, error:Int?) in
                                installingAlert.dismiss(animated: true) {
                                    if (error == 0) {
                                        let message = local("PASSWORD")
                                        let alertController = UIAlertController(title: "Set Password", message: message, preferredStyle: .alert)
                                        alertController.addTextField() { (password) in
                                            password.placeholder = "Password"
                                            password.isSecureTextEntry = true
                                            password.keyboardType = UIKeyboardType.asciiCapable
                                        }

                                        alertController.addTextField() { (repeatPassword) in
                                            repeatPassword.placeholder = "Repeat Password"
                                            repeatPassword.isSecureTextEntry = true
                                            repeatPassword.keyboardType = UIKeyboardType.asciiCapable
                                        }

                                        let setPassword = UIAlertAction(title: local("SET"), style: .default) { _ in
                                            helperCmd(["-p", alertController.textFields![0].text!])
                        
                                            alertController.dismiss(animated: true) {
                                                let alert = UIAlertController.error(title: local("INSTALL_DONE"), message: local("INSTALL_DONE_SUB"))
                                                self.present(alert, animated: true)
                                                completion()
                                            }
                                        }
                                        setPassword.isEnabled = false
                                        alertController.addAction(setPassword)

                                        NotificationCenter.default.addObserver(
                                            forName: UITextField.textDidChangeNotification,
                                            object: nil,
                                            queue: .main
                                        ) { notification in
                                            let passOne = alertController.textFields![0].text
                                            let passTwo = alertController.textFields![1].text
                                            if (passOne!.count > 253 || passOne!.count > 253) {
                                                setPassword.setValue("Too Long", forKeyPath: "title")
                                            } else {
                                                setPassword.setValue("Set", forKeyPath: "title")
                                                setPassword.isEnabled = (passOne == passTwo) && !passOne!.isEmpty && !passTwo!.isEmpty
                                            }
                                        }
                                        self.present(alertController, animated: true)
                                    } else {
                                        let errStr = String(cString: strerror(Int32(error!)))
                                        let alert = UIAlertController.error(title: "Install Failed", message: errStr)
                                        self.present(alert, animated: true)
                                    }
                                }
                            })
                        }
                    } else {
                        let alert = UIAlertController.error(title: "Download Failed", message: error!.localizedDescription)
                        self.present(alert, animated: true)
                    }
                }
            }
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (!envInfo.isRootful) {
            if envInfo.envType == 2 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    let alert = UIAlertController.warning(title: local("HIDDEN"), message: local("HIDDEN_NOTICE"), destructiveBtnTitle: local("PROCEED"), destructiveHandler: {
                        let procursus = "\(Utils().strapCheck().jbFolder)/procursus"

                        let ret = helperCmd(["-e", procursus])
                        if (ret == 0) {
                            spawn(command: "/var/jb/usr/bin/launchctl", args: ["reboot", "userspace"], root: true)
                        } else {
                            let errStr = String(cString: strerror(Int32(ret)))
                            let alert = UIAlertController.error(title: "Failed to link", message: errStr)
                            self.present(alert, animated: true)
                        }
                    })
                    self.present(alert, animated: true)
                }
                return
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (!envInfo.hasChecked) { Utils().prerequisiteChecks() }

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

        navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: customView)]
        let tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
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
        cell.textLabel?.text = tableData[indexPath.section][indexPath.row]
        
        switch tableData[indexPath.section][indexPath.row] {
        case local("REVERT_CELL"):
            let isProcursusStrapped = FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped")
            let isOldProcursusStrapped = FileManager.default.fileExists(atPath: "/.procursus_strapped")
            applySymbolModifications(to: cell, with: "trash", backgroundColor: .systemRed)
            cell.isUserInteractionEnabled = isProcursusStrapped
            cell.textLabel?.textColor = isProcursusStrapped ? .systemRed : .gray
            cell.accessoryType = isProcursusStrapped ? .disclosureIndicator : .none
            cell.imageView?.alpha = cell.isUserInteractionEnabled ? 1.0 : 0.4
            cell.detailTextLabel?.text = isOldProcursusStrapped ? local("REVERT_SUBTEXT") : nil
        case local("SILEO"):
            applyImageModifications(to: cell, with: UIImage(named: "Sileo_logo")!)
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
        case local("ZEBRA"):
            applyImageModifications(to: cell, with: UIImage(named: "Zebra_logo")!)
            cell.accessoryType = .disclosureIndicator
        case local("DIAGNOSTICS"):
            applySymbolModifications(to: cell, with: "note.text", backgroundColor: .systemBlue)
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
        case local("ACTIONS"):
            applySymbolModifications(to: cell, with: "hammer.fill", backgroundColor: .systemOrange)
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
        case local("JBINIT_LOG"):
            applySymbolModifications(to: cell, with: "terminal", backgroundColor: .systemPurple)
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
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

    // MARK: - Main table cells
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemTapped = tableData[indexPath.section][indexPath.row]
        switch itemTapped {
        case local("DIAGNOSTICS"):
            let diagnosticsVC = DiagnosticsVC()
            navigationController?.pushViewController(diagnosticsVC, animated: true)
        case local("JBINIT_LOG"):
            let logviewVC = LogViewer()
            navigationController?.pushViewController(logviewVC, animated: true)
        case local("ACTIONS"):
            let actionsVC = ActionsVC()
            navigationController?.pushViewController(actionsVC, animated: true)
        case local("REVERT_CELL"):
            let alertController = whichAlert(title: local("CONFIRM"), message: local("REVERT_WARNING"))
            let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
            let confirmAction = UIAlertAction(title: local("REVERT_CELL"), style: .destructive) {_ in bootstrap().revert(viewController: self) }
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        case local("SILEO"):
            if (envInfo.sileoInstalled) {
                let alertController = whichAlert(title: local("CONFIRM"), message: local("SILEO_REINSTALL"))
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("REINSTALL"), style: .default) { _ in
                    self.installDebFile(file: "sileo.deb")
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                let alertController = whichAlert(title: local("CONFIRM"), message: local("SILEO_INSTALL"))
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("INSTALL"), style: .default) { _ in
                    self.installDebFile(file: "sileo.deb")
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else {
                self.installStrap(file: "sileo.deb", completion: { })
            }
        case local("ZEBRA"):
            if (envInfo.zebraInstalled) {
                let alertController = whichAlert(title: local("CONFIRM"), message: local("ZEBRA_REINSTALL"))
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("REINSTALL"), style: .default) { _ in
                     self.installDebFile(file: "zebra.deb")
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                let alertController = whichAlert(title: local("CONFIRM"), message: local("ZEBRA_INSTALL"))
                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
                let confirmAction = UIAlertAction(title: local("INSTALL"), style: .default) { _ in
                    self.installDebFile(file: "zebra.deb")
                }
                alertController.addAction(cancelAction)
                alertController.addAction(confirmAction)
                present(alertController, animated: true, completion: nil)
            } else {
                self.installStrap(file: "zebra.deb", completion: { })
            }
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
