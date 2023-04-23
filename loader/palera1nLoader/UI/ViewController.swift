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

extension UIAlertController {
    static func warning(title: String, message: String, destructiveBtnTitle: String?, destructiveHandler: (() -> Void)?) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let destructiveTitle = destructiveBtnTitle, let handler = destructiveHandler {
            alertController.addAction(UIAlertAction(title: destructiveTitle, style: .destructive) { _ in handler() })
        }
        alertController.addAction(UIAlertAction(title: local("CANCEL"), style: .cancel) { _ in return })
        return alertController
    }
    
    static func error(title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: local("CLOSE"), style: .default) { _ in
            bootstrap().cleanUp()
            UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { exit(0) }
        })
        return alertController
    }
    
    static func downloading(_ msg: String.LocalizationValue) -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: local(msg), preferredStyle: .alert)
        let constraintHeight = NSLayoutConstraint(item: alertController.view!, attribute: NSLayoutConstraint.Attribute.height,
                                                  relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute:
                                                    NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 75)
        alertController.view.addConstraint(constraintHeight)
        progressDownload.setProgress(0.0/1.0, animated: true)
        progressDownload.frame = CGRect(x: 25, y: 55, width: 220, height: 0)
        alertController.view.addSubview(progressDownload)
        return alertController
    }
    
    static func spinnerAlert(_ msg: String.LocalizationValue) -> UIAlertController {
        let alertController = UIAlertController(title: nil, message: local(msg), preferredStyle: .alert)
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        alertController.view.addSubview(loadingIndicator)
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()
        return alertController
    }
}

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var tableData = [[local("SILEO"), local("ZEBRA")], [local("UTIL_CELL"), local("OPEN_CELL"), local("REVERT_CELL")]]
    let sectionTitles = [local("INSTALL"), local("DEBUG")]
    
    func downloadFile(url: URL, completion: @escaping (String?, Error?) -> Void) {
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
                                completion(destinationUrl.path, error) // saved
                            } else {
                                completion(destinationUrl.path, error)  // failed to saved
                            }
                        } else {
                            completion(destinationUrl.path, error) // failed to download
                        }
                    }
                }
            } else {
                completion(destinationUrl.path, error) // unknown error
            }
        })
        observation = task.progress.observe(\.fractionCompleted) { progress, _ in
            print("progress: ", progress.fractionCompleted) // remove after testing
            DispatchQueue.main.async {
                progressDownload.setProgress(Float(progress.fractionCompleted/1.0), animated: true)
            }
        }
        task.resume()
    }

    func installDebFile(file: String) {
        let title: String.LocalizationValue = file == "sileo.deb" ? "DL_SILEO" : "DL_ZEBRA"
        let downloadAlert = UIAlertController.downloading(title)
        present(downloadAlert, animated: true)
        
        let server = envInfo.isRootful ? URL(string: "https://static.palera.in")! : URL(string: "https://static.palera.in/rootless")!
        let downloadUrl = server.appendingPathComponent(file)
        deleteFile(file: file)
        
        downloadFile(url: downloadUrl, completion:{(path:String?, error:Error?) in
            DispatchQueue.main.async {
                downloadAlert.dismiss(animated: true) {
                    if (error == nil) {
                        print("Downloaded To: \(path!)")
                        let installingAlert = UIAlertController.spinnerAlert("INSTALLING")
                        self.present(installingAlert, animated: true) {
                            bootstrap().installDebian(deb: path!, withStrap: true, completion:{(msg:String?, error:Int?) in
                                installingAlert.dismiss(animated: true) {
                                    if (error == 0) {
                                        let alert = UIAlertController.error(title: local("INSTALL_DONE"), message: local("INSTALL_DONE_SUB"))
                                        self.present(alert, animated: true)
                                    } else {
                                        let alert = UIAlertController.error(title: "Install Failed", message: "Status: \(error!)")
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
        let downloadAlert = UIAlertController.downloading("DL_STRAP")
        present(downloadAlert, animated: true)

        let CF = Int(floor(kCFCoreFoundationVersionNumber / 100) * 100)
        let server = envInfo.isRootful ? URL(string: "https://static.palera.in")! : URL(string: "https://static.palera.in/rootless")!
        let downloadUrl: URL?
        deleteFile(file: file)
        
        if (!envInfo.isRootful) {
            downloadUrl = server.appendingPathComponent("bootstrap-\(CF).tar")
        } else {
            downloadUrl = server.appendingPathComponent(file)
        }
        
        downloadFile(url: downloadUrl!, completion:{(path:String?, error:Error?) in
            DispatchQueue.main.async {
                downloadAlert.dismiss(animated: true) {
                    if (error == nil) {
                        let installingAlert = UIAlertController.spinnerAlert("INSTALLING")
                        self.present(installingAlert, animated: true) {
                            bootstrap().installBootstrap(tar: path!, completion:{(msg:String?, error:Int?) in
                                installingAlert.dismiss(animated: true) {
                                    if (error == 0) {
                                        completion()
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
                    let alert = UIAlertController.warning(title: "Hide Environment", message: "Your jb-XXXXXXXX folder is still intact while /var/jb isn't, this will re-symlink /var/jb back to it's original folder. You may need to run uicache in utilities after proceeding.", destructiveBtnTitle: "Proceed", destructiveHandler: {
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
        let infoButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "staroflife.circle"), primaryAction: nil, menu: Utils().InfoMenu(viewController: self))
        navigationItem.rightBarButtonItem = infoButton

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
    
    func applyImageModifications(to cell: UITableViewCell, with originalImage: UIImage) {
        let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { context in
            originalImage.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
        }
        cell.imageView?.image = resizedImage
        cell.imageView?.layer.cornerRadius = 7
        cell.imageView?.clipsToBounds = true
        cell.imageView?.layer.borderWidth = 1
        cell.imageView?.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
    }
    
    // MARK: - Viewtable for Sileo/Zebra/Revert/Etc
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = tableData[indexPath.section][indexPath.row]
        
        switch tableData[indexPath.section][indexPath.row] {
        case local("REVERT_CELL"):
            if FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
                cell.isUserInteractionEnabled = true
                cell.accessoryType = .disclosureIndicator
                cell.textLabel?.textColor = .systemRed
            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped"){
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textColor = .gray
                cell.detailTextLabel?.text = local("REVERT_SUBTEXT")
            } else {
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textColor = .gray
            }
        case local("SILEO"):
            if let originalImage = UIImage(named: "Sileo_logo") {
                applyImageModifications(to: cell, with: originalImage)
            }
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
        case local("ZEBRA"):
            if let originalImage = UIImage(named: "Zebra_logo") {
                applyImageModifications(to: cell, with: originalImage)
            }
//            cell.isUserInteractionEnabled = false
            cell.accessoryType = .disclosureIndicator
//            cell.textLabel?.textColor = .gray
        case local("UTIL_CELL"), local("OPEN_CELL"):
            cell.isUserInteractionEnabled = true
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = UIColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1.0)
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
        case local("UTIL_CELL"):
            Utils().actionsTapped(viewController: self)
        case local("OPEN_CELL"):
            Utils().openersTapped(viewController: self)
        case local("REVERT_CELL"):
            let alertController = whichAlert(title: local("CONFIRM"), message: local("REVERT_WARNING"))
            let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
            let confirmAction = UIAlertAction(title: local("REVERT_CELL"), style: .destructive) {_ in bootstrap().revert() }
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            present(alertController, animated: true, completion: nil)
        case local("SILEO"):
            let sileoInstalled = UIApplication.shared.canOpenURL(URL(string: "sileo://")!)
            if (sileoInstalled) {
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
                self.installStrap(file: "bootstrap.tar", completion: {
                    self.installDebFile(file: "libkrw0-tfp0.deb")
                    self.installDebFile(file: "sileo.deb")
                })
            }
        case local("ZEBRA"):
            let zebraInstalled = UIApplication.shared.canOpenURL(URL(string: "zbra://")!)
            if (zebraInstalled) {
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
                self.installStrap(file: "bootstrap.tar", completion: {
                    self.installDebFile(file: "libkrw0-tfp0.deb")
                    self.installDebFile(file: "zebra.deb")
                })
            }
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
