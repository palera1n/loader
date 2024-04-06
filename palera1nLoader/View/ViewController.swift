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
		fetch()
        Go.shared.delegate = self
    }
    
    func setupViews() {
        self.tableView = UITableView(frame: .zero, style: .grouped)
        
        self.tableView.register(ErrorCell.self, forCellReuseIdentifier: ErrorCell.reuseIdentifier)
        self.tableView.register(LoadingCell.self, forCellReuseIdentifier: LoadingCell.reuseIdentifier)
        
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableView.dataSource = self
        self.tableView.delegate = self
        
        self.view.addSubview(tableView)
        self.tableView.constraintCompletely(to: view)
    }
}

extension ViewController {
	func fetch() {
		fetchLoaderData(cfver: corefoundationVersionShort, option: .rootless) { result in
			switch result {
			case .success(let filteredData):
				if filteredData.bootstraps.first?.items.isEmpty ?? true {
					DispatchQueue.main.async {
						let error = NSError(domain: "No Bootstrap Items Data", code: -5, userInfo: nil)
						print("Failed to fetch filtered data: \(error)")
						self.isLoading = false
						self.isError = true
						self.tableView.reloadData()
					}
				} else {
					DispatchQueue.main.async {
						print(filteredData)
						
						// Reset icon images
						self.iconImages.removeAll()
						for _ in filteredData.managers {
							self.iconImages.append(nil)
						}
						
						for (_, manager) in filteredData.managers.enumerated() {
							for managerItem in manager.items {
								guard let imageURL = URL(string: managerItem.icon) else { continue }
								URLSession.shared.dataTask(with: imageURL) { data, _, error in
									guard let data = data, error == nil else { return }
									DispatchQueue.main.async {
										if let image = UIImage(data: data) {
											let managerItemIndex = manager.items.firstIndex(where: { $0.name == managerItem.name })
											if let index = managerItemIndex {
												let rowIndex = self.tableData[0].firstIndex(where: { ($0 as? Loader.ManagerItem)?.name == managerItem.name })
												if let rowIndex = rowIndex {
													self.iconImages[rowIndex] = image
													self.tableView.reloadRows(at: [IndexPath(row: rowIndex, section: 0)], with: .none)
												}
											}
										}
									}
								}.resume()
							}
						}
					}
				}
			case .failure(let error):
				DispatchQueue.main.async {
					print("Failed to fetch filtered data: \(error)")
					self.isLoading = false
					self.isError = true
					self.tableView.reloadData()
				}
			}
		}
	}
}


// MARK: -  UITableView
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int { return 2 }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return 40 }
    
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
        case 0: return .localized("Install")
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

        var footerText = "palera1n Loader • \(appVersion)"
        if paleInfo.palerain_option_rootful {
            footerText += " (rootful)"
        }

        return footerText
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
            //showAlert(for: indexPath, row: row, cellData: cellData, sourceView: tableView.cellForRow(at: indexPath)!)
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
			break
            //showRestoreAlert(sourceView: tableView.cellForRow(at: indexPath)!)
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

