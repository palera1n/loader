//
//  CustomCells.swift
//  loader-rewrite
//
//  Created by samara on 1/29/24.
//

import Foundation
import UIKit

class LoadingCell: UITableViewCell {
    static let reuseIdentifier = "LoadingCell"
    private var stackView: UIStackView!
    private var activityIndicator: UIActivityIndicatorView!
    private var loadingLabel: UILabel!
    
    required init?(coder: NSCoder) { super.init(coder: coder) }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupStackView()
        setupActivityIndicatorView()
        setupLoadingLabel()
    }
    
    private func setupStackView() {
        stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        let heightConstraint = contentView.heightAnchor.constraint(equalToConstant: 45)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
    private func setupActivityIndicatorView() {
        activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.defaultStyle)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
    
    private func setupLoadingLabel() {
        loadingLabel = UILabel()
        loadingLabel.text = String.localized("Loading")
        #if !os(tvOS)
            loadingLabel.font = UIFont.systemFont(ofSize: 15)
        #endif
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(loadingLabel)
    }
}

class ErrorCell: UITableViewCell {
    static let reuseIdentifier = "ErrorCell"
    var retryAction: (() -> Void)?
    private var stackView: UIStackView!
    private var errorLabel: UILabel!

    required init?(coder: NSCoder) { super.init(coder: coder) }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupStackView()
        setupErrorLabel()
    }
    
    private func setupStackView() {
        stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        let heightConstraint = contentView.heightAnchor.constraint(equalToConstant: 45)
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            stackView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
    private func setupErrorLabel() {
        errorLabel = UILabel()
        errorLabel.textAlignment = .center
        errorLabel.numberOfLines = 0
        errorLabel.text = String.localized("Unable to fetch bootstraps.")
        errorLabel.font = UIFont.systemFont(ofSize: 15)
        stackView.addArrangedSubview(errorLabel)
    }
}

extension ViewController {
    func showErrorCell() {
        DispatchQueue.main.async {
            self.isError = true
            self.isLoading = false
            self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }
}


