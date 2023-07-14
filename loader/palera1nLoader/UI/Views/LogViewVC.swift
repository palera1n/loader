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

public var fromAlert = false

class LogViewer: UIViewController {
    
    let dummytext = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris semper aliquam leo, placerat luctus massa vestibulum vitae. Curabitur maximus, neque sed finibus gravida, ante mauris mattis quam, eget placerat ante urna vitae lorem. Nam erat est, varius nec ligula ut, interdum hendrerit metus. Donec vulputate diam porttitor, lobortis massa id, feugiat leo. Morbi at velit sed lacus pretium euismod non quis est. Nam sem enim, malesuada ac sagittis sit amet, elementum ut erat. Nullam sit amet nisl aliquam, fermentum odio non, cursus orci. Aenean ut erat felis. Sed et libero id mauris iaculis maximus vel vel tellus. In hac habitasse platea dictumst."
    
    @objc func closeWithDelay(){
      UIApplication.shared.openSpringBoard()
      exit(0)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (fromAlert) {
            let closeButton = UIBarButtonItem(title: local("CLOSE"), style: .done, target: self, action: #selector(closeWithDelay))
            self.navigationItem.leftBarButtonItem = closeButton
            fromAlert = false
        }
 
        let textView = UITextView()
        self.navigationItem.title = local("LOG_CELL")
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
        
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            textView.topAnchor.constraint(equalTo: self.view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        ])
        
        do {
            let logFileContents = try String(contentsOfFile: logInfo.logFile, encoding: .utf8)
            textView.text = logFileContents
        } catch {
            log(type: .error, msg: "Reading log file: \(logInfo.logFile)")
            if (envInfo.isSimulator) {
                textView.text = "\(dummytext)"
            } else {
                textView.text = "Error: Failed to read loader log file."
            }
        }
        
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareButtonTapped(_:)))
        self.navigationItem.rightBarButtonItem = shareButton
        self.isModalInPresentation = true
    }
    
    @objc func shareButtonTapped(_ sender: UIBarButtonItem) {
        let logFileURL = URL(fileURLWithPath: logInfo.logFile)
        let activityViewController = UIActivityViewController(activityItems: [logFileURL], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = sender
        present(activityViewController, animated: true, completion: nil)
    }
}

