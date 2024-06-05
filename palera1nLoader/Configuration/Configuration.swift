//
//  Fetch.swift
//  loader-rewrite
//
//  Created by samara on 1/29/24.
//

import Foundation
import UIKit

struct LoaderConfiguration: Codable {
	let minLoaderVersion: String
	let palera1nVersionWithMinLoader: String
	let minBridgeBootstrapperVersion: String
	let footerNotice: String?
	let contents: [PlatformContent]

	enum CodingKeys: String, CodingKey {
		case minLoaderVersion = "min_loader_version"
		case palera1nVersionWithMinLoader = "palera1n_version_with_min_loader"
		case minBridgeBootstrapperVersion = "min_bridge_bootstrapper_version"
		case footerNotice = "footer_notice"
		case contents
	}
}

struct PlatformContent: Codable {
	let platform: Int
	let rootful: ContentDetails?
	let rootless: ContentDetails?
}

struct ContentDetails: Codable {
	let dotfile: String
	let bootstraps: [Bootstrap]
	let managers: [Manager]
	let repositories: [Repository]?
}

struct Bootstrap: Codable {
	let cfver: Int
	let uri: String
	let bootstrapDebs: [String]

	enum CodingKeys: String, CodingKey {
		case cfver
		case uri
		case bootstrapDebs = "bootstrap-debs"
	}
}

struct Manager: Codable {
	let name: String
	let uri: String
	let icon: String
	let filePath: String

	enum CodingKeys: String, CodingKey {
		case name
		case uri
		case icon
		case filePath = "filePath"
	}
}

struct Repository: Codable {
	let types: String
	let uris: String
	let suites: String
	let components: String

	enum CodingKeys: String, CodingKey {
		case types = "Types"
		case uris = "URIs"
		case suites = "Suites"
		case components = "Components"
	}
	
	var description: String {
		return "Types: \(types)\nURIs: \(uris)\nSuites: \(suites)\nComponents: \(components)\n"
	}
}

class Config {
	func getURL(from url: URL, completion: @escaping (Result<Data, Error>) -> Void) {
		let task = URLSession.shared.dataTask(with: url) { data, response, error in
			if let error = error {
				completion(.failure(error))
				return
			}
			
			guard let httpResponse = response as? HTTPURLResponse else {
				completion(.failure(NSError(domain: "InvalidResponse", code: -1, userInfo: nil)))
				return
			}
			
			guard (200...299).contains(httpResponse.statusCode) else {
				let errorDescription = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
				completion(.failure(NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorDescription])))
				if let data = data, let responseBody = String(data: data, encoding: .utf8) {
					print("HTTP Error Response: \(responseBody)")
				}
				return
			}
			
			guard let data = data else {
				completion(.failure(NSError(domain: "DataError", code: -1, userInfo: nil)))
				return
			}
			
			completion(.success(data))
		}
		task.resume()
	}

	func parse(data: Data) -> Result<LoaderConfiguration, Error> {
		do {
			let decoder = JSONDecoder()
			decoder.dateDecodingStrategy = .iso8601
			let source = try decoder.decode(LoaderConfiguration.self, from: data)
			return .success(source)
		} catch {
			print("Failed to parse JSON for identifier: Error: \(error)\n")
			return .failure(error)
		}
	}
}


