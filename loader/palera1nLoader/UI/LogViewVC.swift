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
        
        /* VC App Title */
        self.title = "/cores/jbinit.log"
        
        /* TextView Configuration */
        let textView = UITextView()
        textView.backgroundColor = .systemBackground
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        textView.isEditable = false
        textView.isSelectable = false
        textView.isScrollEnabled = true
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        view.addSubview(textView)
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            textView.topAnchor.constraint(equalTo: self.view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        /* Read jbinit Log File */
        let logFilePath = "/cores/jbinit.log"
        
        do {
            let logFileContents = try String(contentsOfFile: logFilePath, encoding: .utf8)
            textView.text = logFileContents
        } catch {
            print("[-] Error Reading ElleKit Log File")
            #if targetEnvironment(simulator)
            textView.text = "Error: Simulator"
            #else
            textView.text = "Error: /cores/jbinit.log not found.\nInfo: Use `-L` when jailbreaking to be able to use this feature."
            #endif
        }
        
        /* UIContextMenu Shenanigans */
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareButtonTapped(_:)))
        shareButton.tintColor = .systemBlue
        
        self.navigationItem.rightBarButtonItem = shareButton
    }
    
    @objc func shareButtonTapped(_ sender: UIBarButtonItem) {
        let logFileURL = URL(fileURLWithPath: "/cores/jbinit.log")
        
        let activityViewController = UIActivityViewController(activityItems: [logFileURL], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true, completion: nil)
    }
}

