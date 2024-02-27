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
    
    var leadingConstraint: NSLayoutConstraint?
    var trailingConstraint: NSLayoutConstraint?
    var topConstraint: NSLayoutConstraint?
    var bottomConstraint: NSLayoutConstraint?
    private var observation: NSKeyValueObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        if #available(iOS 13.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            setHeaderView()
        } else {
            setNavigationBar()
        }
        checkForceRevert()
        
        checkMinimumRequiredVersion()
        retryFetchJSON()
        
        Go.shared.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateiPadConstraints()
    }

    func setupViews() {
        var tableViewStyle: UITableView.Style = .grouped
        
        if #available(iOS 13.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            tableViewStyle = .insetGrouped
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
        
        self.tableView = UITableView(frame: .zero, style: tableViewStyle)

        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(ErrorCell.self, forCellReuseIdentifier: ErrorCell.reuseIdentifier)
        tableView.register(LoadingCell.self, forCellReuseIdentifier: LoadingCell.reuseIdentifier)
    }
    
    func checkForceRevert() {
        if paleInfo.palerain_option_force_revert {
            log(type: .fatal, msg: .localized("Is Force Reverted"))
        } else if paleInfo.palerain_option_failure {
            let nah = UIAlertAction(title: .localized("Dismiss"), style: .cancel, handler: nil)
            let exit = UIAlertAction(title: .localized("Exit Safemode"), style: .default) { _ in
                ExitFailureSafeMode()
            }
            let alert = UIAlertController.coolAlert(title: "", message: .localized("Failure Alert"), actions: [nah, exit])
            self.present(alert, animated: true)
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
        
#if !os(tvOS)
        if #available(iOS 13.0, *) {
            containerView.backgroundColor = UIColor.systemGroupedBackground.withAlphaComponent(1.0)
        } else {
            containerView.backgroundColor = UIColor.white.withAlphaComponent(1.0)
        }
#else
        containerView.backgroundColor = UIColor.lightGray.withAlphaComponent(1.0)
#endif
        
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
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad { return 60.0 } else { return UITableView.automaticDimension }
    }
    
    
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
        case 0: return .localized("Install")
        case 1: return .localized("Troubleshoot")
        default:
            return nil
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
                self?.retryFetchJSON()
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
            showAlert(for: indexPath, row: row, cellData: cellData, sourceView: tableView.cellForRow(at: indexPath)!)
        case (1, 0):
            if #available(iOS 13.0, *), UIDevice.current.userInterfaceIdiom == .pad {
                let sViewController = OptionsViewController()
                let navController = UINavigationController(rootViewController: sViewController)
                present(navController, animated: true, completion: nil)
            } else {
                let options = OptionsViewController()
                navigationController?.pushViewController(options, animated: true)
            }
        case (1, 1):
            showRestoreAlert(sourceView: tableView.cellForRow(at: indexPath)!)
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}





















// MARK: -  Setup navigation bar & iPad views
extension ViewController {
    public func setNavigationBar() {
        if #available(iOS 13.0, *), UIDevice.current.userInterfaceIdiom == .phone {
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
    
    public func setHeaderView() {
        if #available(iOS 13.0, *), UIDevice.current.userInterfaceIdiom == .pad  {
            let headerView = createTableHeaderView(title: "palera1n", version: "")
            tableView.tableHeaderView = headerView
            
            observation = tableView.observe(\.contentSize, options: [.new]) { [weak self] (_, change) in
                guard let self = self else { return }
                if change.newValue != nil {
                    updateTableViewContentInset()
                }
            }
        }
    }
    
    @available(iOS 13.0, *)
    public func createTableHeaderView(title: String, version: String) -> UIView {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 60))
        headerView.backgroundColor = .clear

        let label = UILabel(frame: CGRect(x: 32, y: 0, width: headerView.frame.width - 60, height: 0))
        let attributedString = NSMutableAttributedString(string: "\(title)")

        attributedString.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: 25), range: NSRange(location: 0, length: title.count))
        attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: title.count))

        label.attributedText = attributedString

        label.numberOfLines = 0
        label.sizeToFit()
        label.frame.origin.y = (headerView.frame.height - label.frame.height) / 2

        headerView.addSubview(label)

        headerView.center.x = UIScreen.main.bounds.width / 2

        return headerView
    }


    func updateiPadConstraints() {
        let isIpad = self.view.frame.width >= 568 && UIDevice.current.userInterfaceIdiom == .pad
        let isRunningInFullScreen = UIApplication.shared.delegate?.window??.frame == UIApplication.shared.delegate?.window??.screen.bounds
        let landscapeMultiplier: CGFloat = UIDevice.current.orientation.isLandscape && isRunningInFullScreen ? 2.0 : 1.0

        let leadingConstant: CGFloat = isIpad ? 150 * landscapeMultiplier : 0
        let trailingConstant: CGFloat = isIpad ? -150 * landscapeMultiplier : 0


        [leadingConstraint, trailingConstraint, topConstraint, bottomConstraint].forEach { constraint in
            if let constraint = constraint {
                view.removeConstraint(constraint)
            }
        }

        let newLeadingConstraint = tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: leadingConstant)
        let newTrailingConstraint = tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: trailingConstant)
        let topConstraint = tableView.topAnchor.constraint(equalTo: view.topAnchor)
        let bottomConstraint = tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        [newLeadingConstraint, newTrailingConstraint, topConstraint, bottomConstraint].forEach { constraint in
            constraint.isActive = true
        }

        self.leadingConstraint = newLeadingConstraint
        self.trailingConstraint = newTrailingConstraint
        self.topConstraint = topConstraint
        self.bottomConstraint = bottomConstraint
    }
    
    func updateTableViewContentInset() {
        let viewHeight: CGFloat = view.frame.size.height
        let tableViewContentHeight: CGFloat = tableView.contentSize.height
        let marginHeight: CGFloat = (viewHeight - tableViewContentHeight) / 2.0

        self.tableView.contentInset = UIEdgeInsets(top: marginHeight, left: 0, bottom:  -marginHeight, right: 0)
    }
}
