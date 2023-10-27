//
//  Mods.swift
//  palera1nLoader
//
//  Created by Staturnz on 6/11/23.
//

import Foundation
import UIKit

class mods {
    @available(iOS 13.0, *)
    static public func applySymbolModifications(to cell: UITableViewCell, with symbolName: String, backgroundColor: UIColor) {
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let symbolImage = UIImage(systemName: symbolName, withConfiguration: symbolConfig)?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        let symbolSize = symbolImage?.size ?? .zero
        let imageSize = CGSize(width: 30, height: 30)
        let scale = min((imageSize.width - 6) / symbolSize.width, (imageSize.height - 6) / symbolSize.height)
        let adjustedSymbolSize = CGSize(width: symbolSize.width * scale, height: symbolSize.height * scale)
        let coloredBackgroundImage = UIGraphicsImageRenderer(size: imageSize).image { context in
            backgroundColor.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: imageSize), cornerRadius: 7).fill()
        }
        let mergedImage = UIGraphicsImageRenderer(size: imageSize).image { context in
            coloredBackgroundImage.draw(in: CGRect(origin: .zero, size: imageSize))
            symbolImage?.draw(in: CGRect(x: (imageSize.width - adjustedSymbolSize.width) / 2, y: (imageSize.height - adjustedSymbolSize.height) / 2, width: adjustedSymbolSize.width, height: adjustedSymbolSize.height))
        }
        cell.imageView?.image = mergedImage
        cell.imageView?.layer.cornerRadius = 7
        cell.imageView?.clipsToBounds = true
        cell.imageView?.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
    }
    
    
    static public func applyImageModifications(to cell: UITableViewCell, with originalImage: UIImage) {
        let resizedImage = UIGraphicsImageRenderer(size: CGSize(width: 30, height: 30)).image { context in
            originalImage.draw(in: CGRect(x: 0, y: 0, width: 30, height: 30))
        }
        cell.imageView?.image = resizedImage
        cell.imageView?.layer.cornerRadius = 7
        cell.imageView?.clipsToBounds = true
        cell.imageView?.layer.borderWidth = 1
        cell.imageView?.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.3).cgColor
    }
    
}

extension JsonVC {
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
            titleLabel.leadingAnchor.constraint(equalTo: button.trailingAnchor, constant: 13),
            titleLabel.centerYAnchor.constraint(equalTo: customView.centerYAnchor)
        ])
        let restartButton = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(restartButtonTapped))
        navigationItem.rightBarButtonItem = restartButton
        
        let tripleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tripleTapDebug))
        tripleTapGestureRecognizer.numberOfTapsRequired = 3
        navigationController?.navigationBar.addGestureRecognizer(tripleTapGestureRecognizer)
        
        navigationItem.leftBarButtonItems = [UIBarButtonItem(customView: customView)]
    }
    
    public func setTableView() {
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        tableView.register(ErrorCell.self, forCellReuseIdentifier: "ErrorCell")
        tableView.register(LoadingCell.self, forCellReuseIdentifier: LoadingCell.reuseIdentifier)
    }
    @objc func tripleTapDebug(sender: UIButton) {
        let debugVC = DebugVC()
        let navController = UINavigationController(rootViewController: debugVC)
        navController.modalPresentationStyle = .formSheet
        present(navController, animated: true, completion: nil)
    }
    @objc func restartButtonTapped() {
        self.retryFetchJSON()
    }
}
