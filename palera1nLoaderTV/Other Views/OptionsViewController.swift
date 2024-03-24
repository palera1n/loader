//
//  OptionsViewController.swift
//  palera1nLoaderTV
//
//  Created by samara on 3/23/24.
//

import Foundation
import UIKit

class OptionsViewController: UIViewController {

    var tableData = [
        [String.localized("About"), String.localized("Utilities")],
        [String.localized("Change Download URL")],
        [String.localized("Show Password Prompt")]
    ]
    
    var sectionTitles = [
        "",
        String.localized("Download"),
        ""
    ]
    
    var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateCells()
        self.setupViews()
        self.title = .localized("Options")
    }
    
    func setupViews() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        let imageView = UIImageView(image: UIImage(named: "apple-tv"))
        imageView.contentMode = .scaleAspectFit
        imageView.alpha = 0.5
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
    
    deinit { Preferences.installPathChangedCallback = nil }
}

// MARK: - tableview

extension OptionsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return tableData[section].count }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { return sectionTitles[section] }
    func numberOfSections(in tableView: UITableView) -> Int { return sectionTitles.count }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return 40 }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 1:
            return .localized("Change Download URL Explanation")
        default:
            return nil
        }
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "Cell")
        cell.selectionStyle = .default
        cell.accessoryType = .none
        let cellText = tableData[indexPath.section][indexPath.row]
        cell.textLabel?.text = cellText
        
        switch cellText {
        case String.localized("Utilities"), String.localized("About"), String.localized("Credits"):
            cell.accessoryType = .disclosureIndicator
        case .localized("Change Download URL"):
            if Preferences.installPath != Preferences.defaultInstallPath {
                cell.textLabel?.textColor = UIColor.black.withAlphaComponent(0.8)
                cell.isUserInteractionEnabled = false
                cell.textLabel?.text = Preferences.installPath!
            } else {
                cell.textLabel?.textColor = UIColor.systemBlue
            }
        case .localized("Reset Configuration"):
            cell.textLabel?.textColor = .systemRed
            cell.textLabel?.textAlignment = .center
            
        case .localized("Reboot after Restore"):
            cell.detailTextLabel?.text = Preferences.rebootOnRevert! ? "YES" : "NO"
        default:
            break
        }
        
        
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let cellText = tableData[indexPath.section][indexPath.row]

        switch cellText {
        case .localized("Reboot after Restore"):
            Preferences.rebootOnRevert?.toggle()
            print(Preferences.rebootOnRevert!)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        case .localized("About"):
            let i = InfoViewController()
            navigationController?.pushViewController(i, animated: true)
        case .localized("Utilities"):
            let u = UtilitiesViewController()
            navigationController?.pushViewController(u, animated: true)
        case .localized("Change Download URL"):
            showChangeDownloadURLAlert()
        case .localized("Reset Configuration"):
            resetConfigDefault()
        default:
            break
        }
    }
    
    func updateCells() {
        if Preferences.installPath != Preferences.defaultInstallPath {
            tableData[1].insert(.localized("Reset Configuration"), at: 1)
        }
        Preferences.installPathChangedCallback = { [weak self] newInstallPath in
            self?.handleInstallPathChange(newInstallPath)
        }
    }
    
    private func handleInstallPathChange(_ newInstallPath: String?) {
        if newInstallPath != Preferences.defaultInstallPath {
            tableData[1].insert(.localized("Reset Configuration"), at: 1)
        } else {
            if let index = tableData[1].firstIndex(of: .localized("Reset Configuration")) {
                tableData[1].remove(at: index)
            }
        }

        tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
    }

}


// MARK: - alert for changing the configuration for downloading items

extension OptionsViewController {
    func resetConfigDefault() {
        Preferences.installPath = Preferences.defaultInstallPath
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            UIApplication.prepareForExitAndSuspend()
        }
    }
    
    func showChangeDownloadURLAlert() {
        let alert = UIAlertController(title: .localized("Change Download URL"), message: nil, preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = Preferences.defaultInstallPath
            textField.autocapitalizationType = .none
            textField.addTarget(self, action: #selector(self.textFieldDidChange(_:)), for: .editingChanged)
        }

        let setAction = UIAlertAction(title: .localized("Set"), style: .default) { _ in
            guard let textField = alert.textFields?.first, let enteredURL = textField.text else { return }

            Preferences.installPath = enteredURL
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                UIApplication.prepareForExitAndSuspend()
            }
        }

        setAction.isEnabled = false
        let cancelAction = UIAlertAction(title: .localized("Cancel"), style: .cancel, handler: nil)

        alert.addAction(setAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }


    @objc func textFieldDidChange(_ textField: UITextField) {
        guard let alertController = presentedViewController as? UIAlertController, let setAction = alertController.actions.first(where: { $0.title == .localized("Set") }) else { return }

        let enteredURL = textField.text ?? ""
        setAction.isEnabled = isValidURL(enteredURL)
    }

    func isValidURL(_ url: String) -> Bool {
        let urlPredicate = NSPredicate(format: "SELF MATCHES %@", "https://.*\\.json$")
        return urlPredicate.evaluate(with: url)
    }
}
