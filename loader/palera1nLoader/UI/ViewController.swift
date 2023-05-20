//
//  ViewController.swift
//  pockiiau
//
//  Created by samiiau on 2/27/23.
//  Copyright © 2023 samiiau. All rights reserved.
//

import UIKit
import CoreServices
import Extras

var observation: NSKeyValueObservation?
var progressDownload: UIProgressView = UIProgressView(progressViewStyle: .default)

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var tableData = [
        [local("SILEO"), local("ZEBRA")],
        [local("ACTIONS"), local("DIAGNOSTICS"), local("REVERT_CELL")]
    ]
    
    let sectionTitles = [local("INSTALL"), local("DEBUG")]

    func downloadFile(url: URL, forceBar: Bool = false, output: String? = nil, completion: @escaping (String?, Error?) -> Void) {
        let tempDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        //URL(string: "/var/tmp/palera1nloader/downloads/")!
        
        var destinationUrl = tempDir.appendingPathComponent(url.lastPathComponent)
        if (output != nil) {
            destinationUrl = tempDir.appendingPathComponent(output!)
        }

        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            if error == nil {
                if let response = response as? HTTPURLResponse {
                    if response.statusCode == 200 {
                        if let data = data {
                            if let _ = try? data.write(to: destinationUrl, options: Data.WritingOptions.atomic) {
                                spawn(command: "/cores/binpack/bin/mv", args: [destinationUrl.path, "/var/mobile/Library/palera1n/downloads/\(destinationUrl.lastPathComponent)"])
                                completion("/var/mobile/Library/palera1n/downloads/\(destinationUrl.lastPathComponent)", error)
                                log(type: .info, msg: "Saved to: /var/mobile/Library/palera1n/downloads/\(destinationUrl.lastPathComponent)")
                            } else {
                                completion(destinationUrl.path, error)
                                log(type: .error, msg: "Failed to save file at: \(destinationUrl.path)")
                            }
                        } else {
                            completion(destinationUrl.path, error)
                            log(type: .error, msg: "Failed to download: \(request)")
                        }
                    } else {
                        completion(destinationUrl.path, error)
                        log(type: .error, msg: "Unknown error on download: \(response.statusCode) - \(request)")
                    }
                }
            } else {
                completion(destinationUrl.path, error)
                log(type: .error, msg: "Failed to download: \(request)")
            }
        })
        
        if (url.pathExtension == "zst" || url.pathExtension == "tar" || forceBar) {
            observation = task.progress.observe(\.fractionCompleted) { progress, _ in
                DispatchQueue.main.async {
                    progressDownload.setProgress(Float(progress.fractionCompleted/1.0), animated: true)
                }
            }
        }
        task.resume()
    }

    func installDebFile(file: String) {
        UIApplication.shared.isIdleTimerDisabled = true
        let title: String.LocalizationValue = file == "sileo.deb" ? "DL_SILEO" : "DL_ZEBRA"
        let downloadAlert = UIAlertController.downloading(title)
        present(downloadAlert, animated: true)
        
        let server = envInfo.isRootful ? URL(string: "https://static.palera.in")! : URL(string: "https://static.palera.in/rootless")!
        let downloadUrl = server.appendingPathComponent(file)
        
        downloadFile(url: downloadUrl, forceBar: true, completion:{(path:String?, error:Error?) in
            DispatchQueue.main.async {
                downloadAlert.dismiss(animated: true) {
                    if (error == nil) {
                        let installingAlert = UIAlertController.spinnerAlert("INSTALLING")
                        self.present(installingAlert, animated: true) {
                            bootstrap().installDebian(deb: path!, completion:{(msg:String?, error:Int?) in
                                installingAlert.dismiss(animated: true) {
                                    if (error == 0) {
                                        let alert = UIAlertController.error(title: local("DONE_INSTALL"), message: local("DONE_INSTALL_SUB"))
                                        self.present(alert, animated: true)
                                    } else {
                                        let alert = UIAlertController.error(title: local("ERROR_INSTALL"), message: "Status: \(errorString(Int32(error!)))")
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
        UIApplication.shared.isIdleTimerDisabled = true
        let downloadAlert = UIAlertController.downloading("DL_STRAP")
        present(downloadAlert, animated: true)

        let bootstrapUrl = envInfo.isRootful ? URL(string: "https://static.palera.in")! : URL(string: "https://apt.procurs.us/bootstraps/\(envInfo.CF)")!
        let pkgmgrUrl = envInfo.isRootful ? URL(string: "https://static.palera.in")! : URL(string: "https://static.palera.in/rootless")!
        let bootstrapDownload: URL?
        
        if (!envInfo.isRootful) {bootstrapDownload = bootstrapUrl.appendingPathComponent("bootstrap-ssh-iphoneos-arm64.tar.zst")
        } else {bootstrapDownload = bootstrapUrl.appendingPathComponent("bootstrap-\(envInfo.CF).tar.zst")}
        
        downloadFile(url: pkgmgrUrl.appendingPathComponent("\(file).deb"), completion:{(path:String?, error:Error?) in
            if (error != nil) {
                DispatchQueue.main.async {
                    downloadAlert.dismiss(animated: true) {
                        let alert = UIAlertController.error(title: local("DOWNLOAD_FAIL"), message: error.debugDescription)
                        self.present(alert, animated: true)
                    }
                }
            }
        })

        self.downloadFile(url: bootstrapDownload!, completion:{(path:String?, error:Error?) in
            DispatchQueue.main.async {
                downloadAlert.dismiss(animated: true) {
                    if (error == nil) {
                        let installingAlert = UIAlertController.spinnerAlert("INSTALLING")
                        self.present(installingAlert, animated: true) {
                            bootstrap().installBootstrap(tar: path!, deb: "\(file).deb", completion:{(msg:String?, error:Int?) in
                                installingAlert.dismiss(animated: true) {
                                    if (error == 0) {
                                        let message = local("PASSWORD")
                                        let alertController = UIAlertController(title: local("PASSWORD_SET"), message: message, preferredStyle: .alert)
                                        alertController.addTextField() { (password) in
                                            password.placeholder = local("PASSWORD_TEXT")
                                            password.isSecureTextEntry = true
                                            password.keyboardType = UIKeyboardType.asciiCapable
                                        }

                                        alertController.addTextField() { (repeatPassword) in
                                            repeatPassword.placeholder = local("PASSWORD_REPEAT")
                                            repeatPassword.isSecureTextEntry = true
                                            repeatPassword.keyboardType = UIKeyboardType.asciiCapable
                                        }

                                        let setPassword = UIAlertAction(title: local("SET"), style: .default) { _ in
                                            helper(args: ["-P", alertController.textFields![0].text!])
                        
                                            alertController.dismiss(animated: true) {
                                                let alert = UIAlertController.error(title: local("DONE_INSTALL"), message: local("DONE_INSTALL_SUB"))
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
                                                setPassword.setValue(local("TOO_LONG"), forKeyPath: "title")
                                            } else {
                                                setPassword.setValue(local("SET"), forKeyPath: "title")
                                                setPassword.isEnabled = (passOne == passTwo) && !passOne!.isEmpty && !passTwo!.isEmpty
                                            }
                                        }
                                        self.present(alertController, animated: true)
                                    } else {
                                        let errStr = String(cString: strerror(Int32(error!)))
                                        let alert = UIAlertController.error(title: local("ERROR_INSTALL"), message: errStr)
                                        self.present(alert, animated: true)
                                    }
                                }
                            })
                        }
                    } else {
                        let alert = UIAlertController.error(title: local("DOWNLOAD_FAIL"), message: error.debugDescription)
                        self.present(alert, animated: true)
                    }
                }
            }
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        envInfo.nav = navigationController!
        
        if !fileExists("/var/mobile/Library/palera1n/helper") {
            #if targetEnvironment(simulator)
            #else
            let alert = UIAlertController.error(title: local("NO_PROCEED"), message: local("NO_PROCEED_SIDELOADING"))
            self.present(alert, animated: true)
            return
            #endif
        }

        if fileExists("/var/mobile/Library/palera1n/helper") && envInfo.hasForceReverted {
            let alert = UIAlertController.error(title: local("NO_PROCEED"), message: local("NO_PROCEED_FR"))
            self.present(alert, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (!envInfo.hasChecked) { Utils().prerequisiteChecks() }

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
        button.layer.borderWidth = 0.7
        button.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
        customView.addSubview(button)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "palera1n"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        customView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: customView.leadingAnchor),
            button.centerYAnchor.constraint(equalTo: customView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: button.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: customView.centerYAnchor)
        ])

        // Add triple tap gesture recognizer to navigation bar
        let tripleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tripleTapDebug))
        tripleTapGestureRecognizer.numberOfTapsRequired = 3
        navigationController?.navigationBar.addGestureRecognizer(tripleTapGestureRecognizer)
        navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: customView)]

        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        tableView.dataSource = self
        view.addSubview(tableView)
        
        // Add this to resize the table view when the device is rotated
        view.addConstraints([
            NSLayoutConstraint(item: tableView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: tableView, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1, constant: 0),
        ])
    }
    
    @objc func tripleTapDebug(sender: UIButton) {
            let debugVC = DebugVC()
            let navController = UINavigationController(rootViewController: debugVC)
            navController.modalPresentationStyle = .formSheet
            present(navController, animated: true, completion: nil)
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
            if envInfo.isRootful {
                let isOldProcursusStrapped = FileManager.default.fileExists(atPath: "/.procursus_strapped")
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textColor = .gray
                cell.imageView?.alpha = 0.4
                cell.detailTextLabel?.text = isOldProcursusStrapped ? local("REVERT_SUBTEXT") : nil
            } else if !envInfo.isRootful {
                let isProcursusStrapped = FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped")
                cell.isUserInteractionEnabled = isProcursusStrapped
                cell.textLabel?.textColor = isProcursusStrapped ? .systemRed : .gray
                cell.accessoryType = isProcursusStrapped ? .disclosureIndicator : .none
                cell.imageView?.alpha = cell.isUserInteractionEnabled ? 1.0 : 0.4
            } else {
                cell.isUserInteractionEnabled = false
            }
            applySymbolModifications(to: cell, with: "trash", backgroundColor: .systemRed)
        case local("SILEO"):
            applyImageModifications(to: cell, with: UIImage(named: "Sileo_logo")!)
            if (envInfo.envType == 2) {
                cell.isUserInteractionEnabled = false
            } else {
                cell.isUserInteractionEnabled = true
            }
            cell.accessoryType = .disclosureIndicator
        case local("ZEBRA"):
            applyImageModifications(to: cell, with: UIImage(named: "Zebra_logo")!)
            if (envInfo.envType == 2) {
                cell.isUserInteractionEnabled = false
            } else {
                cell.isUserInteractionEnabled = true
            }
            cell.accessoryType = .disclosureIndicator
        case local("DIAGNOSTICS"):
            applySymbolModifications(to: cell, with: "note.text", backgroundColor: .systemBlue)
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
        case local("ACTIONS"):
            applySymbolModifications(to: cell, with: "hammer.fill", backgroundColor: .systemOrange)
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
        guard let revision = Bundle.main.infoDictionary?["REVISION"] as? String else {
            return nil
        }
        switch section {
        case tableData.count - 1:
            return "palera1n loader • 1.1 (\(revision))"
        case 0:
            return local("PM_SUBTEXT")
        default:
            return nil
        }
    }

    // MARK: - Main table cells
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let itemTapped = tableData[indexPath.section][indexPath.row]
        switch itemTapped {
        case local("DIAGNOSTICS"):
            let diagnosticsVC = DiagnosticsVC()
            navigationController?.pushViewController(diagnosticsVC, animated: true)
        case local("ACTIONS"):
            let actionsVC = ActionsVC()
            navigationController?.pushViewController(actionsVC, animated: true)
        case local("REVERT_CELL"):
            let alertController = whichAlert(title: local("CONFIRM"), message: local("REVERT_WARNING"))
            let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
            let confirmAction = UIAlertAction(title: local("REVERT_CELL"), style: .destructive) {_ in revert(viewController: self) }
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
                self.installStrap(file: "sileo", completion: { })
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
                self.installStrap(file: "zebra", completion: { })
            }
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
