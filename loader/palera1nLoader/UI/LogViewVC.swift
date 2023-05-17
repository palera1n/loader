//
//  LogViewer.swift
//  ElleKit Configurator
//
//  Created by 0x8ff on 3/10/23.
//  Copyright © 2023 0x8ff. All rights reserved.
//
//  Modified to work without Runestone, made to work for palera1nLoader
//

import UIKit

class LogViewer: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let textView = UITextView()
        self.navigationItem.title = "Logs"
        
        let appearance = UINavigationBarAppearance()
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        
        textView.backgroundColor = .systemBackground
        textView.textContainerInset = UIEdgeInsets(top: self.navigationController!.navigationBar.frame.size.height - 25, left: 5, bottom: 8, right: 5)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.textContainer.lineBreakMode = .byClipping
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        //view
        view.backgroundColor = UIColor.systemGray6
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.contentInset = UIEdgeInsets(top: -25, left: 0, bottom: 40, right: 0)
        
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            textView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        do {
            let logFileContents = try String(contentsOfFile: logInfo.logFile, encoding: .utf8)
            textView.text = logFileContents
        } catch {
            log(type: .error, msg: "Reading log file: \(logInfo.logFile)")
            if (envInfo.isSimulator) {
                textView.text = "Error: Simulator"
            } else {
                textView.text = "Error: Failed to read loader log file."
            }
        }
        
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem = shareButton
        self.isModalInPresentation = true
        
        view.addConstraints([
            NSLayoutConstraint(item: textView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: textView, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1, constant: 0),
        ])
    }
    
    @objc func shareButtonTapped(_ sender: UIBarButtonItem) {
        let logFileURL = URL(fileURLWithPath: logInfo.logFile)
        let activityViewController = UIActivityViewController(activityItems: [logFileURL], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true, completion: nil)
    }
}

