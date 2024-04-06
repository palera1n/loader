//
//  DownloadView.swift
//  palera1nLoader
//
//  Created by samara on 3/22/24.
//

import Foundation
import UIKit

protocol BootstrapLabelDelegate: AnyObject {
    func updateBootstrapLabel(withText text: String)
    func updateSpeedLabel(withText text: String)
    func updateDownloadProgress(progress: Double)
}

extension ViewController: BootstrapLabelDelegate {
    func updateBootstrapLabel(withText text: String) {
        DispatchQueue.main.async {
            self.bootstrapLabel.text = text
            #if !os(tvOS)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            #endif
        }
    }
    
    func updateSpeedLabel(withText text: String) {
        DispatchQueue.main.async { self.speedLabel.text = text }
    }
    
    func updateDownloadProgress(progress: Double) {
        DispatchQueue.main.async { self.progressBar.progress = Float(progress) }
    }
    
    func setupContainerView() {
        containerView = UIView()
		containerView.isHidden = true
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor.defaultContainerBackgroundColor
        view.addSubview(containerView)
        
        containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        containerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.defaultStyle)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(activityIndicator)
        
        progressBar = UIProgressView(progressViewStyle: .default)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.tintColor = .white
        containerView.addSubview(progressBar)
        
        bootstrapLabel = UILabel()
        bootstrapLabel.translatesAutoresizingMaskIntoConstraints = false
        bootstrapLabel.textColor = .none
        #if os(tvOS)
        bootstrapLabel.font = UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .subheadline).pointSize)
        #else
        bootstrapLabel.font = UIFont.systemFont(ofSize: 15)
        #endif
        bootstrapLabel.numberOfLines = 0
        bootstrapLabel.textAlignment = .center
        containerView.addSubview(bootstrapLabel)
        
        speedLabel = UILabel()
        speedLabel.translatesAutoresizingMaskIntoConstraints = false
        speedLabel.textColor = .white.withAlphaComponent(0.5)
        #if os(tvOS)
        speedLabel.font = UIFont.systemFont(ofSize: 32)
        #else
        speedLabel.font = UIFont.systemFont(ofSize: 12)
        #endif
        speedLabel.numberOfLines = 0
        speedLabel.textAlignment = .center
        containerView.addSubview(speedLabel)
        
        NSLayoutConstraint.activate([
            activityIndicator.trailingAnchor.constraint(equalTo: bootstrapLabel.leadingAnchor, constant: -8),
            activityIndicator.centerYAnchor.constraint(equalTo: bootstrapLabel.centerYAnchor),
            
            bootstrapLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            bootstrapLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -activityIndicator.bounds.height/2),
            
            progressBar.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            progressBar.topAnchor.constraint(equalTo: bootstrapLabel.bottomAnchor, constant: 16),
            progressBar.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -100),

            speedLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            speedLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -56),
            speedLabel.widthAnchor.constraint(equalTo: containerView.widthAnchor, constant: -100)
        ])

        activityIndicator.startAnimating()
    }
}
