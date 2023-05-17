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
        deleteFile(file: file)
        
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
                        let alert = UIAlertController.error(title: "Download Failed", message: error.debugDescription)
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
                        let alert = UIAlertController.error(title: "Download Failed", message: error.debugDescription)
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
            let alert = UIAlertController.error(title: "Helper not found", message: "Sideloading is not supported, please jailbreak with palera1n before using.")
            self.present(alert, animated: true)
            return
#endif
        }
        
        if fileExists("/var/mobile/Library/palera1n/helper") && envInfo.hasForceReverted {
            let alert = UIAlertController.error(title: "Unable to continue", message: "Reboot the device manually after using --force-revert, jailbreak again to be able to bootstrap.")
            self.present(alert, animated: true)
        }
    }
    
    var tableView = UITableView()
    var userArr = [UserModal]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (!envInfo.hasChecked) { Utils().prerequisiteChecks() }
        
        navigationItem.title = "palera1n"
        var toolbar: UIToolbar!
        
        if !(envInfo.envType == 2) {
            userArr.append(UserModal(titleImg:  #imageLiteral(resourceName: "Sileo_logo"), titleLabel: "Sileo", subTitleLabel: "Modern package manager"))
            userArr.append(UserModal(titleImg:  #imageLiteral(resourceName: "Zebra_logo"), titleLabel: "Zebra", subTitleLabel: "Familiar package manager"))
        }
        
        view.addSubview(blurView)
        tableView.frame = self.view.frame
        tableView.backgroundColor = UIColor.clear
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorColor = UIColor.clear
        self.view.addSubview(tableView)
        tableView.register(CustomTableViewCell.self, forCellReuseIdentifier: "Cell")
        
        toolbar = UIToolbar()
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toolbar)
        
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            toolbar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            toolbar.heightAnchor.constraint(equalToConstant: 44)
        ])

        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let button = UIButton(type: .system)
        button.setTitle("Actions", for: .normal)
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor { (traitCollection) -> UIColor in
                return traitCollection.userInterfaceStyle == .dark ? .white : .black
            },
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        let attributedTitle = NSMutableAttributedString(string: "Tools", attributes: titleAttributes)
        let chevronImageConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        let chevronImage = UIImage(systemName: "chevron.down.circle.fill", withConfiguration: chevronImageConfig)?.withTintColor(.systemGray, renderingMode: .alwaysOriginal)
        let chevronAttachment = NSTextAttachment()
        chevronAttachment.image = chevronImage
        let chevronAttributedString = NSAttributedString(attachment: chevronAttachment)
        let spacing = NSAttributedString(string: " ", attributes: nil)
        attributedTitle.append(spacing)
        attributedTitle.append(chevronAttributedString)
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.addTarget(self, action: #selector(actionsButtonTapped), for: .touchUpInside)
        let actionsButton = UIBarButtonItem(customView: button)

        let item1 = UIBarButtonItem(image: UIImage(systemName: "list.bullet.rectangle"), style: .plain, target: self, action: #selector(item1Tapped))
        let item2 = UIBarButtonItem(image: UIImage(systemName: "info.circle"), style: .plain, target: self, action: #selector(item2Tapped))
        
        toolbar.items = [item1, flexibleSpace, actionsButton, flexibleSpace, item2]
        
        //view
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 0),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 0),
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private lazy var blurView: UIVisualEffectView = {
            let v = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
            v.frame = view.bounds
            v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            return v
        }()
    
    @objc func actionsButtonTapped() {
        let actionVC = ActionsVC()
        let navController = UINavigationController(rootViewController: actionVC)
        navController.modalPresentationStyle = .pageSheet
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]

            let closeButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeButtonTapped))
            actionVC.navigationItem.rightBarButtonItem = closeButton
        }
        present(navController, animated: true, completion: nil)
    }

    @objc func closeButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc func item1Tapped() {
        let diagsVC = DiagnosticsVC()
        let navController = UINavigationController(rootViewController: diagsVC)
        navController.modalPresentationStyle = .pageSheet
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]

            let closeButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeButtonTapped))
            diagsVC.navigationItem.rightBarButtonItem = closeButton
        }
        present(navController, animated: true, completion: nil)
    }
    
    @objc func item2Tapped() {
        let creditsVC = CreditsViewController()
        let navController = UINavigationController(rootViewController: creditsVC)
        navController.modalPresentationStyle = .pageSheet
        if let sheet = navController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]

            let closeButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeButtonTapped))
            creditsVC.navigationItem.rightBarButtonItem = closeButton
        }
        present(navController, animated: true, completion: nil)
    }
    
    // MARK: - Main table cells
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as? CustomTableViewCell else {fatalError("Unable to create cell")}
        cell.titleImg.image = userArr[indexPath.row].titleImg
        cell.titleLabel.text = userArr[indexPath.row].titleLabel
        cell.subTitleLabel.text = userArr[indexPath.row].subTitleLabel
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 105
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedItem = userArr[indexPath.row]
        
        switch selectedItem {
        case let item where item.titleLabel == "Sileo":
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
        case let item where item.titleLabel == "Zebra":
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
            fatalError()
        }
    }
}

extension UIBlurEffect.Style {
    private static var effectAndName: [UIBlurEffect.Style: String] {[
        .systemThinMaterial: "systemThinMaterial"
    ]}
    
    static var effects: [UIBlurEffect.Style] { Array(UIBlurEffect.Style.effectAndName.keys) }
    
    var name: String { UIBlurEffect.Style.effectAndName[self, default: "unknown"] }
}
