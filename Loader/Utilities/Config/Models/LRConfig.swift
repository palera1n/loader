//
//  Fetch.swift
//  loader-rewrite
//
//  Created by samara on 1/29/24.
//

import UIKit.UIDevice

// MARK: - Fetch config
struct LRConfig: Codable {
	/// Minimum loader version that the configuration supports
	///
	/// If the app version is lower than minimum required then
	/// it will tell you to update to the latest palera1n version
	/// with an alert
	let min_loader_version: String
	/// The minimum loader version the latest version of
	/// palera1n supports
	///
	/// As of the versions after beta 9, only 2.0+ is supported
	let palera1n_version_with_min_loader: String
	let min_bridge_bootstrapper_version: String
	/// Message displayed in a section footer
	///
	/// Usually used as a means of telling users emergency or
	/// important messages related to palera1n/jailbreaking in
	/// general
	let footer_notice: String?
	private let contents: [LRConfigContent]
	
	private func findCompatibleContents() -> LRConfigContent? {
		#if targetEnvironment(simulator) && os(tvOS)
		let activePlatform = Int(3) // because I dont have a tv and rely on a sim
		#else
		let activePlatform = Int(dyld_get_active_platform())
		#endif
		
		return contents.filter { content in
			content.platform == activePlatform
		}.first
	}
	
	/// Strap contents
	func content() -> LRConfigContentDetails? {
		findCompatibleContents()?.type()
	}
}

private struct LRConfigContent: Codable {
	fileprivate let platform: Int
	private let rootful: LRConfigContentDetails?
	private let rootless: LRConfigContentDetails?
	
	fileprivate func type() -> LRConfigContentDetails? {
		UIDevice.current.palera1n.palerain_option_rootless
		? rootless
		: rootful
	}
}

// MARK: - Strap data
struct LRConfigContentDetails: Codable {
	private let dotfile: String
	private let bootstraps: [LRBootstrap]
	/// Available package managers
	let managers: [LRManager]
	/// Repositories that will be added
	let repositories: [LRRepository]?
	
	private func _findCompatibleBootstraps() -> LRBootstrap? {
		let currentCFVersion = UIDevice.current.cfVersion.rounded
		let availableVersions = bootstraps.map { $0.cfver }
		
		// If current version is lower than all available bootstraps
		if let minAvailableVersion = availableVersions.min(), Int(currentCFVersion)! < minAvailableVersion {
			return nil
		}
		
		// If exact match exists
		if let exactMatch = bootstraps.filter({ $0.cfver == Int(currentCFVersion) }).first {
			return exactMatch
		}
		
		// If current version is higher than available bootstraps
		if let highestVersion = availableVersions.max(), Int(currentCFVersion)! > highestVersion {
			return bootstraps.filter { $0.cfver == highestVersion }.first
		}
		
		return nil
	}
	
	/// Returns the first compatible bootstrap or nil if none matches
	/// If nil, its expected to immediately backout of the bootstrapping process
	func bootstrap() -> LRBootstrap? {
		_findCompatibleBootstraps()
	}
}

struct LRBootstrap: Codable {
	fileprivate let cfver: Int
	/// Bootstrap tar.zst uri
	let uri: URL
	/// Bootstrap post strap debs
	let bootstrap_deb_uris: [URL]

	enum CodingKeys: String, CodingKey {
		case cfver, uri
		case bootstrap_deb_uris = "bootstrap-debs"
	}
}

struct LRManager: Codable {
	/// Package manager name
	let name: String
	/// Package manager deb uri
	let uri: URL
	/// Package manager image representation uri
	let icon: URL
	/// Package manager install path
	/// Useful for detecting if it is installed, due to them having a common path we're able to keep track of
	let filePath: URL
}

struct LRRepository: Codable {
	private let Types: String
	private let URIs: String
	private let Suites: String
	private let Components: String
	
	/// APT repository data in string format
	var data: String {
		"Types: \(Types)\nURIs: \(URIs)\nSuites: \(Suites)\nComponents: \(Components)\n"
	}
}
