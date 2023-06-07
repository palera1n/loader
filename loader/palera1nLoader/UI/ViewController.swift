//
//  ViewController.swift
//  palera1nLoader
//
//  Created by samiiau on 2/27/23.
//  Copyright © 2023 samiiau. All rights reserved.
//

//import UIKit
//import CoreServices
//import Extras
//
//var observation: NSKeyValueObservation?
//var progressDownload: UIProgressView = UIProgressView(progressViewStyle: .default)
//
//class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
//    var tableData = [
//        [local("SILEO"), local("ZEBRA")],
//        [local("ACTIONS"), local("DIAGNOSTICS"), local("REVERT_CELL")]
//    ]
//
//    let sectionTitles = [local("INSTALL"), local("DEBUG")]
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        envInfo.nav = navigationController!
//
//        /// This sees if the loader app should let the user be able to interact with it,
//        /// if not then a prompt will appear prompting them to close.
//
//        #if !targetEnvironment(simulator)
//        switch true {
//        case !fileExists("/var/mobile/Library/palera1n/helper"):
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                let alert = UIAlertController.error(title: local("NO_PROCEED"), message: local("NO_PROCEED_SIDELOADING"))
//                self.present(alert, animated: true)
//            }
//            return
//
//        case envInfo.hasForceReverted:
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                let alert = UIAlertController.error(title: local("NO_PROCEED"), message: local("NO_PROCEED_FR"))
//                self.present(alert, animated: true)
//            }
//            return
//
//        case (envInfo.CF == 2000):
//            if envInfo.isRootful {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                    let alert = UIAlertController.error(title: local("DOWNLOAD_ERROR"), message: "Rootful on iOS 17 is not supported. You will get no support, and you're on your own.")
//                    self.present(alert, animated: true)
//                }
//                return
//            }
//            return
//        default:
//            break
//        }
//        #endif
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        if !envInfo.hasChecked {
//            Utils().prerequisiteChecks()
//        }
//
//        setNavigationBar()
//        setTableView()
//    }
//
//    private func setNavigationBar() {
//        let appearance = UINavigationBarAppearance()
//        navigationController?.navigationBar.standardAppearance = appearance
//        navigationController?.navigationBar.scrollEdgeAppearance = appearance
//
//        let customView = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 30))
//        customView.translatesAutoresizingMaskIntoConstraints = false
//
//        let button = UIButton(type: .custom)
//        button.translatesAutoresizingMaskIntoConstraints = false
//        button.widthAnchor.constraint(equalToConstant: 25).isActive = true
//        button.heightAnchor.constraint(equalToConstant: 25).isActive = true
//        button.layer.cornerRadius = 6
//        button.clipsToBounds = true
//        button.setBackgroundImage(UIImage(named: "AppIcon"), for: .normal)
//        button.layer.borderWidth = 0.7
//        button.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.5).cgColor
//        customView.addSubview(button)
//
//        let titleLabel = UILabel()
//        titleLabel.translatesAutoresizingMaskIntoConstraints = false
//        titleLabel.text = "palera1n"
//        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
//        customView.addSubview(titleLabel)
//
//        NSLayoutConstraint.activate([
//            button.leadingAnchor.constraint(equalTo: customView.leadingAnchor),
//            button.centerYAnchor.constraint(equalTo: customView.centerYAnchor),
//            titleLabel.leadingAnchor.constraint(equalTo: button.trailingAnchor, constant: 8),
//            titleLabel.centerYAnchor.constraint(equalTo: customView.centerYAnchor)
//        ])
//
//        /// Add triple tap gesture recognizer to navigation bar
//        let tripleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tripleTapDebug))
//        tripleTapGestureRecognizer.numberOfTapsRequired = 3
//        navigationController?.navigationBar.addGestureRecognizer(tripleTapGestureRecognizer)
//        navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: customView)]
//    }
//
//    private func setTableView() {
//        let tableView = UITableView(frame: .zero, style: .insetGrouped)
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//        tableView.delegate = self
//        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
//        tableView.dataSource = self
//        view.addSubview(tableView)
//
//        view.addConstraints([
//            NSLayoutConstraint(item: tableView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0),
//            NSLayoutConstraint(item: tableView, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1, constant: 0),
//        ])
//    }
//
//    @objc func tripleTapDebug(sender: UIButton) {
//            let debugVC = DebugVC()
//            let navController = UINavigationController(rootViewController: debugVC)
//            navController.modalPresentationStyle = .formSheet
//            present(navController, animated: true, completion: nil)
//    }
//
//    func numberOfSections(in tableView: UITableView) -> Int {
//        return sectionTitles.count
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return tableData[section].count
//    }
//
//    // MARK: - Viewtable for Sileo/Zebra/Revert/Etc
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
//        cell.textLabel?.text = tableData[indexPath.section][indexPath.row]
//
//        switch tableData[indexPath.section][indexPath.row] {
//        case local("REVERT_CELL"):
//            if envInfo.isRootful {
//                let isOldProcursusStrapped = FileManager.default.fileExists(atPath: "/.procursus_strapped")
//
//                cell.isUserInteractionEnabled = false
//                cell.textLabel?.textColor = .gray
//                cell.imageView?.alpha = 0.4
//                cell.detailTextLabel?.text = isOldProcursusStrapped ? local("REVERT_SUBTEXT") : nil
//            } else if !envInfo.isRootful {
//                let isProcursusStrapped = FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped")
//                #if !targetEnvironment(simulator)
//                cell.isUserInteractionEnabled = isProcursusStrapped
//                #endif
//                cell.textLabel?.textColor = isProcursusStrapped ? .systemRed : .gray
//                cell.accessoryType = isProcursusStrapped ? .disclosureIndicator : .none
//                cell.imageView?.alpha = cell.isUserInteractionEnabled ? 1.0 : 0.4
//            } else {
//                cell.isUserInteractionEnabled = false
//            }
//            applySymbolModifications(to: cell, with: "trash", backgroundColor: .systemRed)
//        case local("SILEO"):
//            applyImageModifications(to: cell, with: UIImage(named: "Sileo_logo")!)
//            if (envInfo.envType == 2) {
//                cell.isUserInteractionEnabled = false
//            } else {
//                cell.isUserInteractionEnabled = true
//            }
//            cell.accessoryType = .disclosureIndicator
//        case local("ZEBRA"):
//            applyImageModifications(to: cell, with: UIImage(named: "Zebra_logo")!)
//            if (envInfo.envType == 2) {
//                cell.isUserInteractionEnabled = false
//            } else {
//                cell.isUserInteractionEnabled = true
//            }
//            cell.accessoryType = .disclosureIndicator
//        case local("DIAGNOSTICS"):
//            applySymbolModifications(to: cell, with: "note.text", backgroundColor: .systemBlue)
//            cell.isUserInteractionEnabled = true
//            cell.accessoryType = .disclosureIndicator
//        case local("ACTIONS"):
//            applySymbolModifications(to: cell, with: "hammer.fill", backgroundColor: .systemOrange)
//            cell.isUserInteractionEnabled = true
//            cell.accessoryType = .disclosureIndicator
//        default:
//            break
//        }
//        return cell
//    }
//
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return sectionTitles[section]
//    }
//
//    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
//        guard let revision = Bundle.main.infoDictionary?["REVISION"] as? String else {
//            return nil
//        }
//        switch section {
//        case tableData.count - 1:
//            return "palera1n loader • 1.2 (\(revision))"
//        case 0:
//            return local("PM_SUBTEXT")
//        default:
//            return nil
//        }
//    }
//
//    // MARK: - Main table cells
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let itemTapped = tableData[indexPath.section][indexPath.row]
//        switch itemTapped {
//        case local("DIAGNOSTICS"):
//            let diagnosticsVC = DiagnosticsVC()
//            if UIDevice.current.userInterfaceIdiom == .pad {
//                let diagnosticsNavController = UINavigationController(rootViewController: diagnosticsVC)
//                showDetailViewController(diagnosticsNavController, sender: nil)
//            } else {
//                navigationController?.pushViewController(diagnosticsVC, animated: true)
//            }
//
//        case local("ACTIONS"):
//            let actionsVC = ActionsVC()
//            if UIDevice.current.userInterfaceIdiom == .pad {
//                let actionsNavController = UINavigationController(rootViewController: actionsVC)
//                showDetailViewController(actionsNavController, sender: nil)
//            } else {
//                navigationController?.pushViewController(actionsVC, animated: true)
//            }
//
//        case local("REVERT_CELL"):
//            let alertController = whichAlert(title: local("CONFIRM"), message: envInfo.rebootAfter ? local("REVERT_WARNING") : nil)
//            let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
//            let confirmAction = UIAlertAction(title: local("REVERT_CELL"), style: .destructive) { _ in revert(viewController: self) }
//
//            alertController.addAction(cancelAction)
//            alertController.addAction(confirmAction)
//
//            present(alertController, animated: true, completion: nil)
//        case local("SILEO"):
//            if (envInfo.sileoInstalled) {
//                let alertController = whichAlert(title: local("CONFIRM"), message: local("SILEO_REINSTALL"))
//                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
//                let confirmAction = UIAlertAction(title: local("REINSTALL"), style: .default) { _ in
//                    self.installDebFile(file: "sileo.deb")
//                }
//                alertController.addAction(cancelAction)
//                alertController.addAction(confirmAction)
//                present(alertController, animated: true, completion: nil)
//            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
//                let alertController = whichAlert(title: local("CONFIRM"), message: local("SILEO_INSTALL"))
//                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
//                let confirmAction = UIAlertAction(title: local("INSTALL"), style: .default) { _ in
//                    self.installDebFile(file: "sileo.deb")
//                }
//                alertController.addAction(cancelAction)
//                alertController.addAction(confirmAction)
//                present(alertController, animated: true, completion: nil)
//            } else {
//                self.installStrap(file: "sileo", completion: { })
//            }
//        case local("ZEBRA"):
//            if (envInfo.zebraInstalled) {
//                let alertController = whichAlert(title: local("CONFIRM"), message: local("ZEBRA_REINSTALL"))
//                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
//                let confirmAction = UIAlertAction(title: local("REINSTALL"), style: .default) { _ in
//                     self.installDebFile(file: "zebra.deb")
//                }
//                alertController.addAction(cancelAction)
//                alertController.addAction(confirmAction)
//                present(alertController, animated: true, completion: nil)
//            } else if FileManager.default.fileExists(atPath: "/.procursus_strapped") || FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
//                let alertController = whichAlert(title: local("CONFIRM"), message: local("ZEBRA_INSTALL"))
//                let cancelAction = UIAlertAction(title: local("CANCEL"), style: .cancel, handler: nil)
//                let confirmAction = UIAlertAction(title: local("INSTALL"), style: .default) { _ in
//                    self.installDebFile(file: "zebra.deb")
//                }
//                alertController.addAction(cancelAction)
//                alertController.addAction(confirmAction)
//                present(alertController, animated: true, completion: nil)
//            } else {
//                self.installStrap(file: "zebra", completion: { })
//            }
//        default:
//            break
//        }
//
//        tableView.deselectRow(at: indexPath, animated: true)
//    }
//}
