//
//  ViewController.swift
//  palera1nLoaderTV
//
//  Created by samara on 3/22/24.
//

import UIKit
class ViewController: UIViewController {
    
        
    var isLoading = true
    var isError = false
    
    var tableData: [[Any]] = [[]]
    var iconImages: [UIImage?] = []
    var tableView: UITableView!
    var containerView: UIView!

    var bootstrapLabel: UILabel!
    var speedLabel: UILabel!
    var progressBar: UIProgressView!
    
    public var observation: NSKeyValueObservation?
    #if !os(tvOS)
    var hideStatusBar: Bool = false { didSet { setNeedsStatusBarAppearanceUpdate() } }
    override var prefersStatusBarHidden: Bool { return hideStatusBar }
    #endif
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setNavigationBar()
        updateTableViewContentOffset()
        appCheckUp()
        checkMinimumRequiredVersion()
        retryFetchJSON()
        Go.shared.delegate = self
    }
    
    func setupViews() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        let imageView = UIImageView(image: UIImage(named: "apple-tv"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        
        
        stackView.addArrangedSubview(imageView)
        
        self.tableView = UITableView(frame: .zero, style: .grouped)
        self.tableView.register(ErrorCell.self, forCellReuseIdentifier: ErrorCell.reuseIdentifier)
        self.tableView.register(LoadingCell.self, forCellReuseIdentifier: LoadingCell.reuseIdentifier)
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        stackView.addArrangedSubview(tableView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            imageView.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.5),
            imageView.heightAnchor.constraint(equalTo: stackView.heightAnchor) // I
        ])
    }
    
    func updateTableViewContentOffset() {
        let screenHeight = UIScreen.main.bounds.size.height
        let tableViewContentHeight = tableView.contentSize.height

        var contentOffsetY = (screenHeight - tableViewContentHeight) / 2.0

        contentOffsetY = max(-tableView.contentInset.top, contentOffsetY)
        contentOffsetY = min(tableView.contentSize.height - tableView.frame.size.height + tableView.contentInset.bottom, contentOffsetY)

        tableView.contentOffset = CGPoint(x: 0, y: -contentOffsetY)
    }



    func appCheckUp() {
        if paleInfo.palerain_option_force_revert {
            log(type: .info, msg: .localized("Is Force Reverted"))
        } else if paleInfo.palerain_option_failure {
            let nah = UIAlertAction(title: .localized("Dismiss"), style: .cancel, handler: nil)
            let exit = UIAlertAction(title: .localized("Exit Safemode"), style: .default) { _ in
                ExitFailureSafeMode()
            }
            let alert = UIAlertController.coolAlert(title: "", message: .localized("Failure Alert"), actions: [nah, exit])
            self.present(alert, animated: true)
        }
    }
    public func setNavigationBar() {
        let restartButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(restartButtonTapped))
        
        self.title = "palera1n"
        self.navigationItem.title = nil
        self.navigationItem.rightBarButtonItem = restartButton
    }
    
    @objc func restartButtonTapped() { self.retryFetchJSON() }
}

extension UIStackView {
    func addBackground(image: UIImage, alpha: CGFloat) {
        let imageView = UIImageView(image: image)
        imageView.frame = bounds
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(imageView, at: 0)

        let overlayView = UIView(frame: bounds)
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(alpha)
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(overlayView, aboveSubview: imageView)
    }
}


// MARK: -  UITableView
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int { return 2 }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return 40 }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 120 }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let strapValue = Status.installation()
        if section == 0 && (isLoading || isError) {
            return 1
        }
        if section == 0 {
            return tableData[section].count
        }
        if section == 1 {
            return (strapValue == .rootless_installed 
                    || strapValue == .simulated
                    || (!paleInfo.palerain_option_ssv && strapValue == .rootful_installed)
            )
            ? 2
            : 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 1: return .localized("Troubleshoot")
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == tableView.numberOfSections - 1 else {
            return nil
        }

        guard let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return nil
        }

        return "palera1n Loader (TV) • \(appVersion)"
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

