//
//  Fetch.swift
//  loader-rewrite
//
//  Created by samara on 1/29/24.
//

import Foundation
import UIKit

let corefoundationVersionShort = Int(floor(kCFCoreFoundationVersionNumber / 100) * 100)
var jsonInfo: Configuration.LoaderJSON?

public struct Configuration {
    public struct LoaderJSON: Codable {
        let bootstraps: [Bootstrap]
        let managers: [Manager]
        let assets: [Asset]
    }

    // Models
    public struct Bootstrap: Codable {
        let label: String
        let items: [BootstrapItem]
    }

    public struct BootstrapItem: Codable {
        let cfver: String
        let uri: String
    }

    public struct Manager: Codable {
        let label: String
        let items: [ManagerItem]
    }

    public struct ManagerItem: Codable {
        let name: String
        let uri: String
        let icon: String
        let filePaths: [String]
    }

    public struct Asset: Codable {
        let label: String
        let repositories: [AssetRepository]
        let packages: [String]
    }

    public struct AssetRepository: Codable {
        let uri: String
        let suite: String
        let component: String
    }

    // Helper struct for cell information
    public struct CellInfo {
        let names: [String]
        let icons: [String]
        let paths: [String]
    }
}

public struct JailbreakConfiguration {

    // Function to determine jailbreak type
    public func jbType() -> String {
        let initialType = paleInfo.palerain_option_rootful ? "Rootful" : "Rootless"
        
        return Preferences.overrideConfigType! ? toggleJailbreakType(initialType) : initialType
    }

    private func toggleJailbreakType(_ type: String) -> String {
        return (type == "Rootless") ? "Rootful" : "Rootless"
    }

    // Function to get bootstrap URL
    public static func getBootstrapURL(_ json: Configuration.LoaderJSON) -> String? {
        let jailbreakConfiguration = JailbreakConfiguration()
        let jailbreakType = jailbreakConfiguration.jbType()
        let cfver = String(corefoundationVersionShort)
        
        guard let items = json.bootstraps.first(where: { $0.label == jailbreakType })?.items else {
            log(type: .error, msg: "Failed to find bootstrap URL.")
            return nil
        }
        
        let sortedItems = items.sorted { $0.cfver > $1.cfver }
        
        if let bootstrap = sortedItems.first(where: { $0.cfver == cfver }) ?? sortedItems.first(where: { $0.cfver < cfver }) {
            return bootstrap.uri
        }
        
        log(type: .error, msg: "Failed to find bootstrap URL.")
        return nil
    }

    // Function to get manager URL
    public static func getManagerURL(_ json: Configuration.LoaderJSON, _ pkgMgr: String) -> String? {
        let jailbreakConfiguration = JailbreakConfiguration()
        let jailbreakType = jailbreakConfiguration.jbType()

        guard let items = json.managers.first(where: { $0.label == jailbreakType })?.items else {
            log(type: .error, msg: "Failed to find package manager info.")
            return nil
        }
        
        if let info = items.first(where: { $0.name.lowercased() == pkgMgr.lowercased() }) {
            return info.uri
        }
        
        log(type: .error, msg: "Failed to find package manager info.")
        return nil
    }

    // Function to get assets info
    public static func getAssetsInfo(_ json: Configuration.LoaderJSON) -> (repositories: [String], packages: [String])? {
        let jailbreakConfiguration = JailbreakConfiguration()
        let jailbreakType = jailbreakConfiguration.jbType()
        var packages: [String] = []
        var repositories: [String] = []
        
        for asset in json.assets {
            if asset.label == jailbreakType {
                packages = asset.packages
                repositories = asset.repositories.map { "Types: deb\nURIs: \($0.uri)\nSuites: \($0.suite)\nComponents: \($0.component)\n\n" }
            }
        }
        
        if packages.isEmpty && repositories.isEmpty {
            log(type: .error, msg: "Failed to find assets info for \(jailbreakType).")
            return nil
        }
        
        return (packages, repositories)
    }

    // Function to get cell information
    public static func getCellInfo(_ json: Configuration.LoaderJSON) -> Configuration.CellInfo? {
        let jailbreakConfiguration = JailbreakConfiguration()
        let jailbreakType = jailbreakConfiguration.jbType()

        guard let items = json.managers.first(where: { $0.label == jailbreakType })?.items else {
            log(type: .error, msg: "Failed to find package manager info.")
            return nil
        }
        
        var names: [String] = []
        var icons: [String] = []
        var paths: [String] = []
        
        for info in items {
            names.append(info.name)
            icons.append(info.icon)
            paths.append(info.filePaths.joined(separator: ", "))
        }
        
        if names.isEmpty || icons.isEmpty {
            log(type: .error, msg: "Failed to find package manager info.")
            return nil
        }
        
        return Configuration.CellInfo(names: names, icons: icons, paths: paths)
    }
}














// MARK: - Fetch the configuration

extension ViewController: RetryFetchJSONDelegate {
    func fetchJSON() {

        guard let urlString = Preferences.installPath, let url = URL(string: urlString) else {
            
            log(msg: "Invalid URL")
            self.showErrorCell()
            self.isLoading = false
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self else { return }
            
            if let error = error {
                log(type: .error, msg: "Error parsing JSON: \(error)")
                self.showErrorCell()
                self.isLoading = false
                return
            }
            
            guard let data = data else {
                log(type: .error, msg: "No data received")
                self.showErrorCell()
                self.isLoading = false
                return
            }
            
            do {
                let jsonapi = try JSONDecoder().decode(Configuration.LoaderJSON.self, from: data)
                jsonInfo = jsonapi
                guard let cellInfo = JailbreakConfiguration.getCellInfo(jsonapi) else {
                    self.showErrorCell()
                    self.isLoading = false
                    return
                }
                
                self.tableData = [cellInfo.names, cellInfo.icons]
                
                guard JailbreakConfiguration.getBootstrapURL(jsonapi) != nil else {
                    self.showErrorCell()
                    self.isLoading = false
                    return
                }
                
                DispatchQueue.global().async {
                    let iconImages = cellInfo.icons.compactMap { iconURLString -> UIImage? in
                        guard let iconURL = URL(string: iconURLString),
                              let data = try? Data(contentsOf: iconURL),
                              let image = UIImage(data: data) else {
                            return nil
                        }
                        return image
                    }
                    
                    DispatchQueue.main.async {
                        self.iconImages = iconImages
                        self.isLoading = false
                        self.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
                    }
                }
                
            } catch {
                log(type: .error, msg: "Error parsing JSON: \(error)")
                self.showErrorCell()
                self.isLoading = false
                
            }
        }
        
        task.resume()
    }
    
    func retryFetchJSON() {
        isLoading = true
        isError = false
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        
        fetchJSON()
    }
}

protocol RetryFetchJSONDelegate: AnyObject {
    func retryFetchJSON()
}





// MARK: - fetch minimum required

extension ViewController {
    func fetchMinimumRequired(completion: @escaping (Double?) -> Void) {
        guard let url = URL(string: "https://palera.in/required.json") else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                completion(nil)
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let minimumRequired = json?["minimum_required"] as? Double
                completion(minimumRequired)
            } catch {
                completion(nil)
            }
        }.resume()
    }
    
    func checkMinimumRequiredVersion() {
        fetchMinimumRequired { minimumRequired in
            guard let minimumRequired = minimumRequired,
                  let appVersionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                  let appVersion = Double(appVersionString),
                  appVersion < minimumRequired else {
                return
            }
            
            DispatchQueue.main.async {
                self.showMinimumRequiredAlert(message: .localized("Loader Update"))
            }
        }
    }

    func showMinimumRequiredAlert(message: String) {
        let additionalAction = UIAlertAction(title: "Lame", style: .default, handler: nil)
        let alert = UIAlertController.error(title: "", message: message, actions: [additionalAction])
        self.present(alert, animated: true)
    }
}
