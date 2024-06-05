//
//  ViewController.swift
//  loader-rewrite
//
//  Created by samara on 1/29/24.
//

import UIKit

class ViewController: UIViewController {
    
    var isLoading = true
    var isError = false
    
    var tableView: UITableView!
	var iconImages: [UIImage?] = []
    var containerView: UIView!

    var bootstrapLabel: UILabel!
    var speedLabel: UILabel!
    var progressBar: UIProgressView!
    
	public var data: LoaderConfiguration?
	let rootType = Status.installation()
	var platform: UInt32!
	var basePath: ContentDetails?

    public var observation: NSKeyValueObservation?
    #if !os(tvOS)
    var hideStatusBar: Bool = false { didSet { setNeedsStatusBarAppearanceUpdate() } }
    override var prefersStatusBarHidden: Bool { return hideStatusBar }
    #endif

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setNavigationBar()
        #if os(tvOS)
        updateTableViewContentOffset()
        #endif
        appCheckUp()
        Go.shared.delegate = self
		loadConfig()
    }
    
    func setupViews() {
        self.tableView = UITableView(frame: .zero, style: .grouped)
        self.tableView.register(ErrorCell.self, forCellReuseIdentifier: ErrorCell.reuseIdentifier)
        self.tableView.register(LoadingCell.self, forCellReuseIdentifier: LoadingCell.reuseIdentifier)
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.dataSource = self
        self.tableView.delegate = self
        #if os(tvOS)
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        let imageView = UIImageView(image: UIImage(named: "apple-tv"))
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(tableView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
            imageView.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.5),
            imageView.heightAnchor.constraint(equalTo: stackView.heightAnchor) // I
        ])
        #else
        
        self.view.addSubview(tableView)
        self.tableView.constraintCompletely(to: view)
        #endif
        self.setupContainerView()
    }
    
    func appCheckUp() {
        if paleInfo.palerain_option_force_revert {
			log(type: .fatal, msg: .localized("Is Force Reverted", arguments: device))
        } else if paleInfo.palerain_option_failure {
            let nah = UIAlertAction(title: .localized("Dismiss"), style: .cancel, handler: nil)
            let exit = UIAlertAction(title: .localized("Exit Safemode"), style: .default) { _ in
                ExitFailureSafeMode()
            }
            let alert = UIAlertController.coolAlert(title: "", message: .localized("Failure Alert"), actions: [nah, exit])
            self.present(alert, animated: true)
        }
    }
    #if os(tvOS)
    func updateTableViewContentOffset() {
        let screenHeight = UIScreen.main.bounds.size.height
        let tableViewContentHeight = tableView.contentSize.height

        var contentOffsetY = (screenHeight - tableViewContentHeight) / 2.0

        contentOffsetY = max(-tableView.contentInset.top, contentOffsetY)
        contentOffsetY = min(tableView.contentSize.height - tableView.frame.size.height + tableView.contentInset.bottom, contentOffsetY)

        tableView.contentOffset = CGPoint(x: 0, y: -contentOffsetY)
    }
    
    public func setNavigationBar() {
        let restartButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshConfig))
        
        self.title = "palera1n"
        self.navigationItem.title = nil
        self.navigationItem.rightBarButtonItem = restartButton
    }
    #endif
}

#if os(tvOS)
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
#endif

// MARK: -  UITableView
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int { return 2 }
    #if os(tvOS)
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { return 120 }
    #else
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return 40 }
    #endif
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let strapValue = Status.installation()
		let strapValue2 = Status.checkInstallStatus()
        if section == 0 && (isLoading || isError) {
            return 1
        }
        if section == 0 {
			return (basePath?.managers.count)!
        }
        if section == 1 {
            return (
				strapValue2 == .rootless_installed
             || strapValue == .simulated
             || strapValue2 == .rootful_installed
            )
            ? 2
            : 1
        }
        return 0
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
		if section == 0 && (isLoading || isError) {
			return nil
		}
		if section == 0 {
			return data?.footerNotice
		}

        guard let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return nil
        }

        #if os(tvOS)
        var footerText = "palera1n Loader (TV) • \(appVersion)"
        #else
        var footerText = "palera1n Loader • \(appVersion)"
        if paleInfo.palerain_option_rootful {
            footerText += " (rootful)"
        }
        #endif

        return footerText
    }
	
	func tableView(_ tableView: UITableView, didUpdateFocusIn context: UITableViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
		// Check if the next focused item is a table view cell
		if let nextFocusedIndexPath = context.nextFocusedIndexPath,
		   let _ = tableView.cellForRow(at: nextFocusedIndexPath) {
			// Print the focused section and row index
			print("Focused section: \(nextFocusedIndexPath.section), row: \(nextFocusedIndexPath.row)")
		}
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
			let source = basePath?.managers[indexPath.row]
			cell.textLabel?.text = source?.name
			#if !os(tvOS)
			SectionIcons.sectionImage(to: cell, with: iconImages[indexPath.row]!)
			#endif
        } else {
            let row = indexPath.row
            if row == 0 {
                cell.textLabel?.text = .localized("Options")
            } else {
                if (paleInfo.palerain_option_ssv && paleInfo.palerain_option_rootful) {
                    cell.textLabel?.text = .localized("Clean FakeFS")
                } else {
                    cell.textLabel?.text = .localized("Restore System")
                }
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
            let cellData = basePath?.managers[row]
			print(cellData!)
			//break
			showAlert(row: row, title: cellData?.name, sourceView: tableView.cellForRow(at: indexPath)!)
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

// MARK: -  Getting data!
extension ViewController {
	@objc public func refreshConfig(_ sender: Any) {
		DispatchQueue.main.async {
			self.isLoading = true
			self.isError = false
			self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
		}
		
		loadConfig()
	}
	
	func loadConfig() {
		let config = Config()
		
		config.getURL(from: URL(string: Preferences.installPath!)!) { result in
			switch result {
			case .success(let data):
				let parseResult = config.parse(data: data)
				switch parseResult {
				case .success(let config):
					self.data = config
					
					self.platform = Status().getActivePlatform().rawValue
					print(self.platform!)
					print(self.rootType)
					self.basePath = {
						guard let content = self.data?.contents.first(where: { $0.platform == self.platform }) else { return nil }
						switch self.rootType {
						case .rootful: return content.rootful
						case .rootless: return content.rootless
						case .simulated: return content.rootful
						}
					}()
					
					let iconImages = self.basePath?.managers.compactMap { manager in
						guard let iconURL = URL(string: manager.icon),
							  let data = try? Data(contentsOf: iconURL),
							  let image = UIImage(data: data) else {
							return UIImage(named: "unknown")
						}
						return image
					}

					self.iconImages = iconImages!

					DispatchQueue.main.async {
						self.isLoading = false
						self.isError = false
						self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
					}
					self.checkMinimumRequiredVersion()
					break
				case .failure(_):
					DispatchQueue.main.async {
						self.isLoading = false
						self.isError = true
						self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
					}
					break
				}
			case .failure(_):
				DispatchQueue.main.async {
					self.isLoading = false
					self.isError = true
					self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
				}
				break
			}
		}
	}
	
	func checkMinimumRequiredVersion() {
		guard let minimumRequiredString = data?.minLoaderVersion,
			  let minimumRequired = Double(minimumRequiredString),
			  let appVersionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
			  let appVersion = Double(appVersionString),
			  appVersion < minimumRequired else {
			return
		}
		DispatchQueue.main.async {
			let lame = UIAlertAction(title: .localized("Dismiss"), style: .default, handler: nil)
			let alert = UIAlertController.error(title: "", message: .localized("Loader Update"), actions: [lame])
			self.present(alert, animated: true)
		}
	}
}
