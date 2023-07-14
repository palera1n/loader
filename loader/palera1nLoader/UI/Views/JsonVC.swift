//
//  JsonVC.swift
//  palera1nLoader
//
//  Created by samara on 6/6/23.
//

import Foundation
import UIKit

var observation: NSKeyValueObservation?
var progressDownload: UIProgressView = UIProgressView(progressViewStyle: .default)

class JsonVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var tableData: [[Any]] = [[]]
    var sectionTitles = [""]
    var iconImages: [UIImage?] = []
    var isLoading = true
    var isError = false
    var errorMessage = "Unable to fetch bootstraps."
    var tableView: UITableView!
    
    func installDebFile(file: String) {
        UIApplication.shared.isIdleTimerDisabled = true
        let title: String.LocalizationValue = "\(local("DOWNLOADING"))"
        let downloadAlert = UIAlertController.downloading(title)
        present(downloadAlert, animated: true)
        
        let downloadUrl = getManagerURL(envInfo.jsonInfo!, file)!

        downloadFile(url: URL(string: downloadUrl)!, forceBar: true, completion:{(path:String?, error:Error?) in
            DispatchQueue.main.async {
                downloadAlert.dismiss(animated: true) {
                    if (error == nil) {
                        let installingAlert = UIAlertController.spinnerAlert("INSTALLING")
                        self.present(installingAlert, animated: true) {
                            bootstrap.installDebian(deb: path!, completion:{(msg:String?, error:Int?) in
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
    
    func downloadFile(url: URL, forceBar: Bool = false, output: String? = nil, completion: @escaping (String?, Error?) -> Void) {
        let tempDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        var destinationUrl = tempDir.appendingPathComponent(url.lastPathComponent)
        if (output != nil) {destinationUrl = tempDir.appendingPathComponent(output!)}

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
    
    func installStrap(file: String, completion: @escaping () -> Void) {
        UIApplication.shared.isIdleTimerDisabled = true
        let downloadAlert = UIAlertController.downloading("DL_STRAP")
        present(downloadAlert, animated: true)

        let bootstrapUrl = getBootstrapURL(envInfo.jsonInfo!)!
        let pkgmgrUrl = getManagerURL(envInfo.jsonInfo!, file)!
        
        downloadFile(url: URL(string: pkgmgrUrl)!, completion:{(path:String?, error:Error?) in
            if (error != nil) {
                DispatchQueue.main.async {
                    downloadAlert.dismiss(animated: true) {
                        let alert = UIAlertController.error(title: local("DOWNLOAD_FAIL"), message: error.debugDescription)
                        self.present(alert, animated: true)
                    }
                }
            }
        })

        self.downloadFile(url:  URL(string: bootstrapUrl)!, completion:{(path:String?, error:Error?) in
            DispatchQueue.main.async {
                downloadAlert.dismiss(animated: true) {
                    if (error == nil) {
                        let installingAlert = UIAlertController.spinnerAlert("INSTALLING")
                        self.present(installingAlert, animated: true) {
                            bootstrap.installBootstrap(tar: path!, deb: "\(file).deb", completion:{(msg:String?, error:Int?) in
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
        fetchJSON()
        
        #if !targetEnvironment(simulator)
        switch true {
        case !fileExists("/var/mobile/Library/palera1n/helper"):
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let alert = UIAlertController.error(title: local("NO_PROCEED"), message: local("NO_PROCEED_SIDELOADING"))
                self.present(alert, animated: true)
            }
            return

        case envInfo.hasForceReverted:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let alert = UIAlertController.error(title: local("NO_PROCEED"), message: local("NO_PROCEED_FR"))
                self.present(alert, animated: true)
            }
            return
            
        case (envInfo.CF == 2000):
            if envInfo.isRootful {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    let alertController = whichAlert(title: "Oopsy :3", message: "Rootful on iOS 17 is not supported. You will get no support, and you're on your own.")
                    let cancelAction = UIAlertAction(title: local("CLOSE"), style: .cancel, handler: nil)
                    alertController.addAction(cancelAction)
                    
                    self.present(alertController, animated: true, completion: nil)
                }
                return
            }
            return
        default:
            break
        }
        #endif
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !envInfo.hasChecked {
            Check.prerequisites()
        }
        
        setNavigationBar()
        setTableView()
    }
    
    private func setNavigationBar() {
        let appearance = UINavigationBarAppearance()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        let customView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
        customView.translatesAutoresizingMaskIntoConstraints = false
        
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(equalToConstant: 30).isActive = true
        button.heightAnchor.constraint(equalToConstant: 30).isActive = true
        button.layer.cornerRadius = 7
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
            titleLabel.leadingAnchor.constraint(equalTo: button.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: customView.centerYAnchor)
        ])
      let restartButton = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(restartButtonTapped))
      navigationItem.rightBarButtonItem = restartButton
        /// Add triple tap gesture recognizer to navigation bar
        let tripleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tripleTapDebug))
        tripleTapGestureRecognizer.numberOfTapsRequired = 3
        navigationController?.navigationBar.addGestureRecognizer(tripleTapGestureRecognizer)
        navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: customView)]
    }
    
    private func setTableView() {
      tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tableView.register(ErrorCell.self, forCellReuseIdentifier: "ErrorCell")
        tableView.register(LoadingCell.self, forCellReuseIdentifier: LoadingCell.reuseIdentifier)
    }
    
    @objc func tripleTapDebug(sender: UIButton) {
            let debugVC = DebugVC()
            let navController = UINavigationController(rootViewController: debugVC)
            navController.modalPresentationStyle = .formSheet
            present(navController, animated: true, completion: nil)
    }
    
    @objc func restartButtonTapped() {
        self.retryFetchJSON()
    }
    
    func fetchJSON() {
        guard let url = URL(string: "\(envInfo.jsonURI)") else {
            log(type: .error, msg: "Invalid JSON URL")
            self.showErrorCell(with: errorMessage)
            self.isLoading = false
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self else { return }
            
            if let error = error {
                log(type: .error, msg: "Error parsing JSON: \(error)")
                self.showErrorCell(with: self.errorMessage)
                self.isLoading = false
                return
            }
            
            guard let data = data else {
                log(type: .error, msg: "No data received")
                self.showErrorCell(with: self.errorMessage)
                self.isLoading = false
                return
            }
            
            do {
                //let json = try JSONSerialization.jsonObject(with: data, options: [])
                let jsonapi = try JSONDecoder().decode(loaderJSON.self, from: data)
                envInfo.jsonInfo = jsonapi
                self.tableData = [getCellInfo(jsonapi)!.names, getCellInfo(jsonapi)!.icons]
                self.sectionTitles = [""]
                
                log(msg: "[JSON CELL DATA] \(self.tableData)")
                
                DispatchQueue.global().async {
                    let iconImages = getCellInfo(jsonapi)!.icons.map { iconURLString -> UIImage? in
                        guard let iconURL = URL(string: iconURLString),
                              let data = try? Data(contentsOf: iconURL),
                              let image = UIImage(data: data) else {
                            return nil
                        }
                        return image
                    }
                    
                    DispatchQueue.main.async {
                        self.iconImages = iconImages
                        self.isLoading = false
                        self.tableView.reloadData()
                    }
                }
                
            } catch {
                log(type: .error, msg: "Error parsing JSON: \(error)")
                self.showErrorCell(with: self.errorMessage)
                self.isLoading = false
                
            }
        }
        
        /// Start the network request
        task.resume()
    }
    
    func showErrorCell(with message: String) {
        isError = true
        errorMessage = message
        DispatchQueue.main.async {
            self.isLoading = false
            self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: // Fetching section
            switch (isLoading, isError) {
            case (true, _):
                return 1
            case (_, true):
                return 1
            default:
                return tableData[section].count
            }
        case 1:
            return 3
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch (section, isLoading, isError) {
        case (0, true, _):
            return local("DOWNLOADING")
        case (0, _, true):
            return local("DOWNLOAD_ERROR")
        case (0, _, _):
            return local("INSTALL")
        case (1, _, _):
            return local("DEBUG")
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard let revision = Bundle.main.infoDictionary?["REVISION"] as? String else {
            return nil
        }
        switch section {
        case 1:
            return "palera1n loader • 1.2 (\(revision))"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) ?? UITableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
        
        switch (isLoading, isError, indexPath.section) {
        case (true, _, 0):
            let loadingCell = tableView.dequeueReusableCell(withIdentifier: LoadingCell.reuseIdentifier, for: indexPath) as! LoadingCell
            loadingCell.isUserInteractionEnabled = false
            loadingCell.startLoading()
            return loadingCell
            
        case (_, true, 0):
            let errorCell = tableView.dequeueReusableCell(withIdentifier: "ErrorCell", for: indexPath) as! ErrorCell
            errorCell.errorMessage = errorMessage
            errorCell.isUserInteractionEnabled = false
            errorCell.retryAction = { [weak self] in
                self?.retryFetchJSON()
            }
            return errorCell
            
        default:
            break
        }
        
        switch (indexPath.section, indexPath.row) {
        case (1, 0):
            cell.textLabel?.text = local("ACTIONS")
            cell.accessoryType = .disclosureIndicator
            cell.isUserInteractionEnabled = true
            cell.textLabel?.textColor = .label
            cell.imageView?.alpha = 1.0
          mods.applySymbolModifications(to: cell, with: "hammer.fill", backgroundColor: .systemGray)
        case (1, 1):
            cell.textLabel?.text = local("DIAGNOSTICS")
            cell.accessoryType = .disclosureIndicator
            cell.isUserInteractionEnabled = true
            cell.textLabel?.textColor = .label
            cell.imageView?.alpha = 1.0
            mods.applySymbolModifications(to: cell, with: "note.text", backgroundColor: .systemBlue)
        case (1, 2):
            mods.applySymbolModifications(to: cell, with: "trash", backgroundColor: .systemRed)
            cell.textLabel?.text = local("REVERT_CELL")
            if envInfo.isRootful {
                cell.isUserInteractionEnabled = false
                cell.textLabel?.textColor = .gray
                cell.imageView?.alpha = 0.4
            } else if !envInfo.isRootful {
                let isProcursusStrapped = FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped")
                cell.isUserInteractionEnabled = isProcursusStrapped
                cell.textLabel?.textColor = isProcursusStrapped ? .systemRed : .gray
                cell.accessoryType = isProcursusStrapped ? .disclosureIndicator : .none
                cell.imageView?.alpha = cell.isUserInteractionEnabled ? 1.0 : 0.4
            } else {
                cell.isUserInteractionEnabled = false
            }
        default:
            cell.isUserInteractionEnabled = true
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.textColor = .label
            cell.imageView?.alpha = 1.0
            
            cell.textLabel?.text = tableData[indexPath.section][indexPath.row] as? String
            mods.applyImageModifications(to: cell, with: iconImages[indexPath.row]!)
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch (indexPath.section, indexPath.row) {
        case (0, let row):
            let itemTapped = tableData[indexPath.section][indexPath.row]

            guard let name = itemTapped as? String else {
                return
            }

          var filePaths = getCellInfo(envInfo.jsonInfo!)!.paths
            let procursusStrappedExists = FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped")

            let alertController = whichAlert(title: "", message: nil)
            let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
            alertController.addAction(cancelAction)

            log(msg: "[JSON PATH DATA] \(getCellInfo(envInfo.jsonInfo!)!.paths)")

            if (0..<filePaths.count).contains(row) {
                let filePath = filePaths[row]
                let regex = try! NSRegularExpression(pattern: "\"(.*?)\"")
                let range = NSRange(filePath.startIndex..<filePath.endIndex, in: filePath)
                let matches = regex.matches(in: filePath, range: range)

                for match in matches {
                    if let matchRange = Range(match.range(at: 1), in: filePath) {
                        let filePath = String(filePath[matchRange])
                        filePaths.append(filePath)
                    }
                }

                let components = filePath.components(separatedBy: ",")
                let exists = components.contains { path in
                    let trimmedPath = path.trimmingCharacters(in: .whitespaces)
                    return FileManager.default.fileExists(atPath: trimmedPath)
                }

                let lowercaseName = name.lowercased()

                log(msg: "[JSON PATH DATA] \(filePath) exists? \(exists).")

                if procursusStrappedExists {
                    alertController.message = exists ? "\(name) is already installed at \(filePath)" : local("Install \(name)?")
                    let pkgAction = UIAlertAction(title: exists ? local("REINSTALL") : local("INSTALL"), style: .default) { _ in
                        self.installDebFile(file: "\(lowercaseName)")
                    }
                    alertController.addAction(pkgAction)
                } else {
                    alertController.message = "Strap and \(name) is not installed. Install now?"
                    let installAction = UIAlertAction(title: local("INSTALL"), style: .default) { _ in
                        self.installStrap(file: name.lowercased()) {}
                    }
                    alertController.addAction(installAction)
                }
            }

            present(alertController, animated: true, completion: nil)
            
        case (1, 0):
          let actionsVC = ActionsVC()

          UIDevice.current.userInterfaceIdiom == .pad ?
          
          showDetailViewController(UINavigationController(rootViewController: actionsVC), sender: nil) :
          navigationController?.pushViewController(actionsVC, animated: true)

            
        case (1, 1):
          let diagnosticsVC = DiagnosticsVC()

          UIDevice.current.userInterfaceIdiom == .pad ?
          
          showDetailViewController(UINavigationController(rootViewController: diagnosticsVC), sender: nil) :
          navigationController?.pushViewController(diagnosticsVC, animated: true)
            
        case (1, 2):
            let alertController = whichAlert(title: local("CONFIRM"), message: envInfo.rebootAfter ? local("REVERT_WARNING") : nil)
            let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
            let confirmAction = UIAlertAction(title: local("REVERT_CELL"), style: .destructive) { _ in bootstrap.revert(viewController: self) }
            
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            
            present(alertController, animated: true, completion: nil)
            
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func retryFetchJSON() {
        isLoading = true
        isError = false
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        
        fetchJSON()
    }
    
}

