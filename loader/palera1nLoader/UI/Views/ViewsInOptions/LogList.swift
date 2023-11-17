//
//  LogList.swift
//  palera1nLoader
//
//  Created by samara on 11/14/23.
//

import Foundation
import UIKit

class LogListVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {

    var logFiles: [String] = []
    var filteredLogFiles: [String] = []

    let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = nil
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        return searchController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        shitUI()
        loadshit()
    }

    func shitUI() {
        title = LocalizationManager.shared.local("LOG_CELL")

        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)

        let inset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        tableView.contentInset = inset
        tableView.scrollIndicatorInsets = inset

        NSLayoutConstraint.activate([
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func loadshit() {
        let fileManager = FileManager.default
        let logsDirectory = "/tmp/palera1n/logs"

        do {
            let files = try fileManager.contentsOfDirectory(atPath: logsDirectory)
            logFiles = files.filter { $0.hasSuffix(".log") }
            filteredLogFiles = logFiles
            tableView.reloadData()
        } catch {
            print("Error reading log files: \(error.localizedDescription)")
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLogFiles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = filteredLogFiles[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .default
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedLog = filteredLogFiles[indexPath.row]
        let logViewer = LogViewer()
        logViewer.logFilename = selectedLog
        tableView.deselectRow(at: indexPath, animated: true)
        navigationController?.pushViewController(logViewer, animated: true)
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            filteredLogFiles = logFiles
            tableView.reloadData()
            return
        }

        filteredLogFiles = logFiles.filter { $0.lowercased().contains(searchText.lowercased()) }
        UIView.transition(with: tableView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.tableView.reloadData()
        }, completion: nil)
    }
}
