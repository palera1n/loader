//
//  ViewController.swift
//  loader-rewrite
//
//  Created by samara on 1/29/24.
//

import UIKit

class ViewController: UIViewController {
    
    var tableData: [[Any]] = [[]]
    
    var containerView: UIView!
    
    var isLoading = true
    var isError = false
    
    var iconImages: [UIImage?] = []
    var tableView: UITableView!
    
    var bootstrapLabel: UILabel!
    var progressBar: UIProgressView!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkMinimumRequiredVersion()
        fetchJSON()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBar()
        setupViews()
        checkForceRevert()
        Go.shared.delegate = self
    }
    
    func setupViews() {
        self.tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.constraintCompletely(to: view)
        tableView.register(ErrorCell.self, forCellReuseIdentifier: ErrorCell.reuseIdentifier)
        tableView.register(LoadingCell.self, forCellReuseIdentifier: LoadingCell.reuseIdentifier)
    }
    
    func checkForceRevert() {
        if paleInfo.palerain_option_force_revert {
            log(type: .fatal, msg: .localized("Is Force Reverted"))
        }
    }
}

// MARK: - ViewController Downloading+install container

protocol BootstrapLabelDelegate: AnyObject {
    func updateBootstrapLabel(withText text: String)
    func updateDownloadProgress(progress: Double)
}

extension ViewController: BootstrapLabelDelegate {
    
    func updateBootstrapLabel(withText text: String) {
        DispatchQueue.main.async {
            self.bootstrapLabel.text = text
        }
    }
    
    func updateDownloadProgress(progress: Double) {
        DispatchQueue.main.async {
            self.progressBar.progress = Float(progress)
        }
    }
    
    func setupContainerView() {
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            containerView.backgroundColor = UIColor.systemGroupedBackground.withAlphaComponent(1.0)
        } else {
            containerView.backgroundColor = UIColor.white.withAlphaComponent(1.0)
        }
        
        view.addSubview(containerView)

        containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        var activityIndicator: UIActivityIndicatorView!
        if #available(iOS 13.0, *) {
            activityIndicator = UIActivityIndicatorView(style: .medium)
        } else {
            activityIndicator = UIActivityIndicatorView(style: .white)
        }
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(activityIndicator)
        
//        progressBar = UIProgressView(progressViewStyle: .default)
//        progressBar.translatesAutoresizingMaskIntoConstraints = false
//        containerView.addSubview(progressBar)

        bootstrapLabel = UILabel()
        bootstrapLabel.translatesAutoresizingMaskIntoConstraints = false
        bootstrapLabel.textColor = .none
        bootstrapLabel.font = UIFont.systemFont(ofSize: 15)
        bootstrapLabel.textAlignment = .center

        containerView.addSubview(bootstrapLabel)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -activityIndicator.bounds.height),

            bootstrapLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            bootstrapLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: activityIndicator.bounds.height/2),

//            progressBar.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
//            progressBar.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
//            progressBar.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -16),
        ])


        activityIndicator.startAnimating()
    }



}



// MARK: -  UITableView
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int { return 2 }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return 40 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let strapValue = Status.installation()
        
        if section == 0 {
            if isLoading || isError {
                return 1
            } else {
                return tableData[section].count
            }
        } else {
            return (strapValue == .rootless_installed || strapValue == .simulated) ? 2 : 1
        }
    }

        
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return .localized("Install")
        default:
            return .localized("Troubleshoot")
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        let totalSections = tableView.numberOfSections
        if section == totalSections - 1 {
            if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                var footerText = "palera1n Loader • \(appVersion)"
                
                if paleInfo.palerain_option_rootful {
                    footerText += " (rootful)"
                }
                
                return footerText
            }
        }

        return nil
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseIdentifier = "Cell"
        let cell = UITableViewCell(style: .default, reuseIdentifier: reuseIdentifier)
        
        cell.isUserInteractionEnabled = true
        cell.selectionStyle = .default
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.textColor = .none
        cell.imageView?.alpha = 1.0
        cell.imageView?.image = nil
        
        if indexPath.section == 0 {
            if let specialCell = createSpecialCell(for: tableView, at: indexPath) { return specialCell }
            cell.textLabel?.text = tableData[indexPath.section][indexPath.row] as? String
            SectionIcons.sectionImage(to: cell, with: iconImages[indexPath.row]!)
        } else {
            let row = indexPath.row
            if row == 0 {
                cell.textLabel?.text = .localized("Options")
            } else {
                cell.textLabel?.text = .localized("Restore System")
                cell.textLabel?.textColor = .systemRed
            }
        }
        
        return cell
    }
    
    func createSpecialCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell? {
        if isLoading {
            let loadingCell = tableView.dequeueReusableCell(withIdentifier: LoadingCell.reuseIdentifier, for: indexPath) as! LoadingCell
            loadingCell.isUserInteractionEnabled = false
            return loadingCell
        } else if isError {
            let errorCell = tableView.dequeueReusableCell(withIdentifier: ErrorCell.reuseIdentifier, for: indexPath) as! ErrorCell
            errorCell.selectionStyle = .none
            errorCell.retryAction = { [weak self] in
                self?.fetchJSON()
            }
            return errorCell
        }
        
        return nil
    }

    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.section, indexPath.row) {
        case (0, let row):
            if isError || isLoading { break }
            let cellData = tableData[indexPath.section][row] as? String
            #warning("clean up this code for later")
            showAlert(for: indexPath, row: row, cellData: cellData, sourceView: tableView.cellForRow(at: indexPath)!)
        case (1, 0):
            let options = OptionsViewController()
            
            navigationController?.pushViewController(options, animated: true)
        case (1, 1):
            showRestoreAlert(sourceView: tableView.cellForRow(at: indexPath)!)
        default:
            break
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

// MARK: -  Setup navigation bar
extension ViewController {
    public func setNavigationBar() {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }

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
            titleLabel.leadingAnchor.constraint(equalTo: button.trailingAnchor, constant: 14),
            titleLabel.centerYAnchor.constraint(equalTo: customView.centerYAnchor)
        ])
        
        navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: customView)]
    }
}
