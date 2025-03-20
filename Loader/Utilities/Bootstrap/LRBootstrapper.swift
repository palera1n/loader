//
//  LRBootstrapper.swift
//  Loader
//
//  Created by samara on 13.03.2025.
//

import UIKit

// MARK: - Protocal
protocol LRBootstrapperDelegate {
	func updateStepItemStatus(_ section: String, item: String, with status: StepStatus)
	func updateStepItemStatusForName(named item: String, with status: StepStatus)
	func updateStepGroupFocus(for section: Int)
	func bootstrapFinish()
}

// MARK: - Class
class LRBootstrapper: NSObject {
	public let callback: LRBootstrapperDelegate?
	private var _shouldBootstrap: Bool
	private let _config: LRConfig?
	private let _password: String
	private let _manager: LRManager?
	
	enum LRBootstrapperError: Error, LocalizedError  {
		case downloadFailed(Error)
		case bootstrapFailed(String)
		case dpkgFailed
	}
	
	public var downloadCompletionHandlers: [URLSessionDownloadTask: (String?, Error?) -> Void] = [:]
	public var downloadTaskToDestinationMap: [URLSessionDownloadTask: URL] = [:]

	public var lastStatusItem: (section: String, item: String)? = nil
	
	public var bootstrapFilePath: String? = nil
	public var packageFilePaths: [String] = []
	
	init(
		callback: LRBootstrapperDelegate? = nil,
		config: LRConfig? = nil,
		manager: LRManager? = nil,
		sudo_password: String,
		shouldBootstrap: Bool = true
	) {
		self.callback = callback
		self._config = config
		self._manager = manager
		self._password = sudo_password
		self._shouldBootstrap = shouldBootstrap
		super.init()
	}
	
	// MARK: Download
	
	public func prepareFiles() async throws {
		return try await withCheckedThrowingContinuation { continuation in
			let dispatchGroup = DispatchGroup()
			
			let errorLock = NSLock()
			var firstError: Error?
			
			func downloadResource(urls: [URL], itemLabel: String) {
				dispatchGroup.enter()
				
				self.setItemStatus(
					.localized("Download"),
					item: itemLabel,
					with: .inProgress
				)
				
				download(urls) { results in
					if let (_, error) = results.first(where: { _, error in error != nil }) {
						errorLock.lock()
						if firstError == nil, let downloadError = error {
							firstError = LRBootstrapperError.downloadFailed(downloadError)
							self.setItemStatus(
								.localized("Download"),
								item: itemLabel,
								with: .failed
							)
						}
						errorLock.unlock()
					} else {
						self.setItemStatus(
							.localized("Download"),
							item: itemLabel,
							with: .completed
						)
					}
					
					dispatchGroup.leave()
				}
			}

			if _shouldBootstrap, let url = _config?.content()?.bootstrap()?.uri {
				downloadResource(urls: [url], itemLabel: .localized("Downloading Base Bootstrap"))
			}
			
			if _shouldBootstrap, let urls = _config?.content()?.bootstrap()?.bootstrap_deb_uris {
				downloadResource(urls: urls, itemLabel: .localized("Downloading Required Packages"))
			}
			
			if let url = _manager?.uri {
				downloadResource(urls: [url], itemLabel: .localized("Downloading Package Managers"))
			}
			
			// wait for all downloads to complete
			dispatchGroup.notify(queue: .global()) { [weak self] in
				guard let self = self else {
					continuation.resume(throwing: LRBootstrapperError.bootstrapFailed("Self was deallocated"))
					return
				}
				
				if let error = firstError {
					continuation.resume(throwing: error)
				} else {
					self.setGroupFocus(for: 1)
					continuation.resume(returning: ())
				}
			}
		}
	}
	
	// MARK: Bootstrap
	
	public func bootstrap() async throws {
		self.setLastItemStatusAndNew(
			.localized("Bootstrap"),
			item: .localized("Preparing Environment")
		)
		
		#if !targetEnvironment(simulator) && !DEBUG
		// jailbreak utilities like Filza will create /var/jb if opened before bootstrapping
		// so we will forcefully remove it if we are rootless
		if UIDevice.current.palera1n.palerain_option_rootless {
			_ = LREnvironment.execute(.binpack("/bin/rm"), ["-rf", "/var/jb"])
		}
		#endif
		
		self.setLastItemStatusAndNew(
			.localized("Bootstrap"),
			item: .localized("Installing Base Bootstrap")
		)
				
		let (ret, resultDescription) = LREnvironment.jbd.deployBootstrap(
			with: bootstrapFilePath!,
			password: _password
		)
		if ret != 0 {
			self.setItemStatus(
				.localized("Bootstrap"),
				item: .localized("Installing Base Bootstrap"),
				with: .failed
			)
			throw LRBootstrapperError.bootstrapFailed(resultDescription)
		}
		
		self.setLastItemStatusAndNew(
			.localized("Bootstrap"),
			item: .localized("Preparing Repositories")
		)
		
		if let repos = _config?.content()?.repositories {
			let data = repos.map {
				$0.data
			}.joined(separator: "\n")
			
			// highly unlikely chance that writing into a file will fail
			// if someone with a custom config fucks it up, thats not on us
			let (ret, resultDescription) = LREnvironment.jbd.overwriteFile(
				with: data,
				to: .jb_prefix("/etc/apt/sources.list.d/palera1n.sources")
			)
			if ret != 0 {
				self.setItemStatus(
					.localized("Bootstrap"),
					item: .localized("Preparing Repositories"),
					with: .failed
				)
				throw LRBootstrapperError.bootstrapFailed(resultDescription)
			}
		}
		
		LREnvironment.jbd.reloadLaunchdJailbreakEnvironment()
		self.setGroupFocus(for: 2)
	}
	
	// MARK: Post bootstrap - packages
	
	public func installPackages() async throws {
		self.setLastItemStatusAndNew(
			.localized("Install"),
			item: .localized("Installing Packages")
		)
		
		if !packageFilePaths.isEmpty {
			let ret = LREnvironment.execute(.jb_prefix("/usr/bin/dpkg"), ["-i"] + packageFilePaths,
				environmentPath: ["/usr/bin"]
			)
			if ret != 0 {
				self.setItemStatus(
					.localized("Install"),
					item: .localized("Installing Packages"),
					with: .failed
				)
				throw LRBootstrapperError.dpkgFailed
			}
			
			LREnvironment.execute(.binpack("/usr/bin/uicache"), ["-a"])
		}
		
		try? await Task.sleep(nanoseconds: 1_000_000)
		self.callback?.bootstrapFinish()
	}
}
