//
//  Header.swift
//  palera1nLoader
//
//  Created by samara on 3/16/24.
//

import Foundation
import UIKit

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
        
        let restartButton = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refreshConfig))
        
        self.title = "palera1n"
        self.navigationItem.title = nil
        self.navigationItem.rightBarButtonItem = restartButton
        self.navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: customView)]
    }
}
