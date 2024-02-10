//
//  PreferredLanguageViewController.swift
//  Antoine
//
//  Created by Serena on 24/02/2023.
//
/*
import UIKit

#warning("This is taken from https://github.com/NSAntoine/Antoine, thank you.")

class PreferredLanguageViewController: UITableViewController {
    lazy var languages = Language.availableLanguages
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = .localized("Language")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return Preferences.preferredLanguageCode != nil ? 2 : 1
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { return 40 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return languages.count
        default:
            fatalError()
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        
        if (indexPath.section, indexPath.row) == (0, 0) {
            cell = UITableViewCell()
            cell.textLabel?.text = .localized("Use System Language")
            let uiSwitch = UISwitch()
            uiSwitch.isOn = Preferences.preferredLanguageCode == nil
            uiSwitch.addTarget(self, action: #selector(useSystemLanguageToggled(sender:)), for: .valueChanged)
            cell.accessoryView = uiSwitch
        } else {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            let lang = languages[indexPath.row]
            cell.accessoryType = Preferences.preferredLanguageCode == lang.languageCode ? .checkmark : .none
            cell.textLabel?.text = lang.displayName
            cell.detailTextLabel?.text = lang.subtitleText
            cell.detailTextLabel?.textColor = .systemGray
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        let languageSelected = languages[indexPath.row]
        Preferences.preferredLanguageCode = languageSelected.languageCode
        tableView.reloadSections([1], with: .automatic)
        
        let alert = UIAlertController(title: .localized("Restart Application for changes to fully apply"),
                                      message: nil, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @objc func useSystemLanguageToggled(sender: UISwitch) {
        if sender.isOn {
            UserDefaults.standard.set(nil, forKey: "UserPreferredLanguageCode")
            Bundle.preferredLocalizationBundle = .makeLocalizationBundle()
            tableView.deleteSections([1], with: .fade)
        } else {
            Preferences.preferredLanguageCode = Locale.current.languageCode
            tableView.insertSections([1], with: .fade)
        }
    }
}
*/
