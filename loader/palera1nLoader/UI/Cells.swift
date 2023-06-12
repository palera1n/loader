//
//  Cells.swift
//  palera1nLoader
//
//  Created by Staturnz on 6/11/23.
//

import Foundation
import UIKit

class LoadingCell: UITableViewCell {
    static let reuseIdentifier = "LoadingCell"
    
    private var activityIndicator: UIActivityIndicatorView!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupActivityIndicatorView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupActivityIndicatorView()
    }
    
    private func setupActivityIndicatorView() {
        activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func startLoading() {
        activityIndicator.startAnimating()
    }
}

class ErrorCell: UITableViewCell {
    static let reuseIdentifier = "ErrorCell"
    
    var errorMessage: String? {
        didSet {
            textLabel?.text = errorMessage
        }
    }
    
    var retryAction: (() -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        textLabel?.textColor = .red
        textLabel?.textAlignment = .center
        textLabel?.numberOfLines = 0
        
        let retryButton = UIButton(type: .system)
        retryButton.setTitle("Retry", for: .normal)
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        accessoryView = retryButton
        
        accessoryView?.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        textLabel?.textColor = .red
        textLabel?.textAlignment = .center
        textLabel?.numberOfLines = 0
        
        let retryButton = UIButton(type: .system)
        retryButton.setTitle("Retry", for: .normal)
        retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        accessoryView = retryButton
        
        accessoryView?.frame = CGRect(x: 0, y: 0, width: 60, height: 30)
    }
    
    @objc private func retryButtonTapped() {
        retryAction?()
    }
}
