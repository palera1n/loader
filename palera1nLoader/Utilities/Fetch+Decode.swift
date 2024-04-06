//
//  Fetch.swift
//  loader-rewrite
//
//  Created by samara on 1/29/24.
//

import Foundation
import UIKit

let corefoundationVersionShort = Int(floor(kCFCoreFoundationVersionNumber / 100) * 100)
var jsonInfo: Loader?

public struct Loader: Codable {
	public struct BootstrapItem: Codable {
		let cfver: String
		let uri: String
	}

	public struct Bootstrap: Codable {
		let label: String
		let items: [BootstrapItem]
	}

	public struct ManagerItem: Codable {
		let name: String
		let uri: String
		let icon: String
		let filePaths: [String]
	}

	public struct Manager: Codable {
		let label: String
		let items: [ManagerItem]
	}

	public struct AssetRepository: Codable {
		let uri: String
		let suite: String
		let component: String
	}

	public struct Asset: Codable {
		let label: String
		let repositories: [AssetRepository]
		let packages: [String]
	}

	public enum PaleRainOption: String, Codable {
		case rootful = "Rootful"
		case rootless = "Rootless"
	}

	let bootstraps: [Bootstrap]
	let managers: [Manager]
	let assets: [Asset]

	public func paleRainData(for option: PaleRainOption, cfver: Int) -> (bootstraps: [Loader.Bootstrap], managers: [Loader.Manager], assets: [Loader.Asset]) {
		let filteredBootstraps = bootstraps.filter { $0.label == option.rawValue }
		let filteredManagers = managers.filter { $0.label == option.rawValue }
		let filteredAssets = assets.filter { $0.label == option.rawValue }
		
		var bootstrapsItems = [Loader.BootstrapItem]()
		for bootstrap in filteredBootstraps {
			let filteredItems = bootstrap.items.filter { Int($0.cfver)! <= cfver }
			if let lastItem = filteredItems.last {
				bootstrapsItems.append(lastItem)
			}
		}
		
		let filteredBootstrapsWithCfver = filteredBootstraps.map { Loader.Bootstrap(label: $0.label, items: bootstrapsItems) }
		
		return (filteredBootstrapsWithCfver, filteredManagers, filteredAssets)
	}
}

public func fetchLoaderData(cfver: Int, option: Loader.PaleRainOption, completion: @escaping (Result<(bootstraps: [Loader.Bootstrap], managers: [Loader.Manager], assets: [Loader.Asset]), Error>) -> Void) {
	guard let url = URL(string: Preferences.installPath!) else {
		completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
		return
	}
	
	let task = URLSession.shared.dataTask(with: url) { data, response, error in
		if let error = error {
			completion(.failure(error))
			return
		}
		
		guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
			completion(.failure(NSError(domain: "Server Error", code: -2, userInfo: nil)))
			return
		}
		
		guard let data = data else {
			completion(.failure(NSError(domain: "No Data", code: -3, userInfo: nil)))
			return
		}
		
		do {
			let decoder = JSONDecoder()
			let loader = try decoder.decode(Loader.self, from: data)
			let filteredData = loader.paleRainData(for: option, cfver: cfver)
			completion(.success(filteredData))
		} catch {
			completion(.failure(error))
		}
	}
	
	task.resume()
}
