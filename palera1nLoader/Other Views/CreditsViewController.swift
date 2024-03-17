//
//  CreditsViewController.swift
//  palera1nLoader
//
//  Created by samara on 2/6/24.
//

import UIKit

class CreditsViewController: UITableViewController {
    
    struct Credit: Decodable {
        let name: String
        let github: String
        let desc: String?
    }
    
    struct CreditsSection: Decodable {
        let name: String
        let data: [Credit]
    }
    
    var creditsSections: [CreditsSection] = []
    var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = .localized("Credits")
        if #available(iOS 13.0, *), UIDevice.current.userInterfaceIdiom == .pad {
            tableView = UITableView(frame: .zero, style: .insetGrouped)
        } else {
            tableView = UITableView(frame: .zero, style: .grouped)
        }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "CreditCell")
        
        // Initialize activity indicator
        if #available(iOS 13.0, *), #available(tvOS 15.0, *) {
            activityIndicator = UIActivityIndicatorView(style: .medium)
        } else {
            #if os(tvOS)
            activityIndicator = UIActivityIndicatorView(style: .white)
            #else
            activityIndicator = UIActivityIndicatorView(style: .gray)
            #endif
        }
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        
        fetchCreditsData()
    }
    
    func fetchCreditsData() {
        activityIndicator.startAnimating()
        
        if let url = URL(string: "https://palera.in/data/credits.json") {
            URLSession.shared.dataTask(with: url) { [weak self] (data, _, _) in
                defer {
                    DispatchQueue.main.async {
                        self?.activityIndicator.stopAnimating()
                    }
                }
                
                guard let data = data else { return }
                
                do {
                    let decoder = JSONDecoder()
                    let container = try decoder.decode([String: [CreditsSection]].self, from: data)
                    
                    if let sections = container["sections"] {
                        self?.creditsSections = sections
                        DispatchQueue.main.async {
                            UIView.transition(with: self?.tableView ?? UIView(), duration: 0.35, options: .transitionCrossDissolve, animations: {
                                self?.tableView.reloadData()
                            }, completion: nil)
                        }

                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            }
            .resume()
        }
    }
}

extension CreditsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int { return creditsSections.count }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return creditsSections[section].data.count }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "CreditCell")
        
        let credit = creditsSections[indexPath.section].data[indexPath.row]
        cell.textLabel?.text = credit.name
        cell.textLabel?.textColor = .systemBlue
        
        if let desc = credit.desc {
            cell.detailTextLabel?.text = desc
        }
        
        cell.detailTextLabel?.textColor = .systemGray
        cell.accessoryType = .disclosureIndicator
        
        if indexPath.section == 0 {
            if let imageURL = URL(string: "https://github.com/\(credit.github).png") {
                URLSession.shared.dataTask(with: imageURL) { data, _, _ in
                    if let data = data {
                        DispatchQueue.main.async {
                            if let image = UIImage(data: data) {
                                let resizedImage = image.resize(to: CGSize(width: 40, height: 40))
                                cell.imageView?.image = resizedImage.roundedImage
                                cell.setNeedsLayout()
                            }
                        }
                    }
                }.resume()
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let credit = creditsSections[indexPath.section].data[indexPath.row]
        if let githubURL = URL(string: "https://github.com/\(credit.github)") {
            UIApplication.shared.open(githubURL, options: [:], completionHandler: nil)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section < creditsSections.count else {
            return nil
        }
        
        return creditsSections[section].name.capitalized
    }
}
