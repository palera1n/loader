//
//  Header.swift
//  palera1nLoader
//
//  Created by samara on 3/16/24.
//

import Foundation
import UIKit
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
        
        let restartButton = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(restartButtonTapped))
        
        navigationItem.rightBarButtonItem = restartButton
        navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: customView)]
    }
    
    @objc func restartButtonTapped() {
        self.retryFetchJSON()
    }
    
    public func setHeaderView() {
        if #available(iOS 13.0, *), UIDevice.current.userInterfaceIdiom == .pad  {
            let headerView = createTableHeaderView(title: "palera1n", version: "")
            tableView.tableHeaderView = headerView
            
            observation = tableView.observe(\.contentSize, options: [.new]) { [weak self] (_, change) in
                guard let _ = self else { return }
                if change.newValue != nil {
                    self!.updateTableViewContentInset()
                }
            }

        }
    }
    
    @available(iOS 13.0, *)
    public func createTableHeaderView(title: String, version: String) -> UIView {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 60))
        headerView.backgroundColor = .clear

        let label = UILabel(frame: CGRect(x: 16, y: 0, width: headerView.frame.width - 60, height: 0))
        let attributedString = NSMutableAttributedString(string: "\(title)")

        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 40, weight: UIFont.Weight(rawValue: 0.6)), range: NSRange(location: 0, length: title.count))
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

        let leadingConstant: CGFloat = isIpad ? 150 : 0
        let trailingConstant: CGFloat = isIpad ? -150 : 0


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
