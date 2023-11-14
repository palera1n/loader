//
//  LogViewer.swift
//  palera1nLoader
//
//  Created by 0x8ff on 3/10/23.
//  Copyright © 2023 0x8ff. All rights reserved.
//
//  Modified to work without Runestone, made to work for palera1nLoader
//

import UIKit

class LogViewer: UIViewController {

    var logFilename: String?

    override func viewDidLoad() {
        super.viewDidLoad()
 
        let textView = UITextView()
        
        self.navigationItem.title = logFilename
        if #available(iOS 13.0, *) {
            self.view.backgroundColor = UIColor.systemBackground
            let appearance = UINavigationBarAppearance()
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
            textView.backgroundColor = .systemBackground
        }
        textView.textContainerInset = UIEdgeInsets(top: self.navigationController!.navigationBar.frame.size.height - 50, left: 5, bottom: 8, right: 5)
        textView.isEditable = false
        textView.isSelectable = true
        textView.isScrollEnabled = true
        textView.textContainer.lineBreakMode = .byClipping
        if #available(iOS 13.0, *) {
            textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        } else {
            textView.font = UIFont.systemFont(ofSize: 12)
        }
        
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            textView.topAnchor.constraint(equalTo: self.view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        if let logFilename = logFilename {
            do {
                let logFilePath = "/tmp/palera1n/logs/" + logFilename
                let logFileContents = try String(contentsOfFile: logFilePath, encoding: .utf8)

                if logFileContents.isEmpty {
                    textView.text = "Shh you found a secret!!!"
                } else {
                    textView.text = logFileContents
                }
            } catch {
                let errorMsg = "Error reading log file: \(logFilename)"
                textView.text = errorMsg
            }
        }
        
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem = shareButton
    }
    
    @objc func shareButtonTapped(_ sender: UIBarButtonItem) {
        let logFileURL = URL(fileURLWithPath: "/tmp/palera1n/logs/" + logFilename!)
        let activityViewController = UIActivityViewController(activityItems: [logFileURL], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true, completion: nil)
    }
}

