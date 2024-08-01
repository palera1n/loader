//
//  Install.swift
//  loader-rewrite
//
//  Created by samara on 1/30/24.
//

import Foundation
import UIKit
import MachO
import Darwin.POSIX
import Bridge

var device: String {
	let currentDevice = UIDevice.current
	switch currentDevice.userInterfaceIdiom {
	case .pad: return "iPad"
	case .phone: return "iPhone"
	case .tv: return "Apple TV"
	case .mac: return "Mac"
	default: return "Unknown Device"
	}
}

enum jbStatus {
	case simulated
	case rootful
	case rootless
}

enum installStatus {
	case rootful_installed
	case rootless_installed
	case rootless_partial
	case none
}

enum DyldPlatform: UInt32 {
	case macOS = 1
	case iOS = 2
	case tvOS = 3
	case bridgeOS = 5
	case macCatalyst = 6
	case unknown = 0
}

class Status {
	func getActivePlatform() -> DyldPlatform {
		let platformRawValue = dyld_get_active_platform()
		return DyldPlatform(rawValue: platformRawValue)
		?? {
			#if os(iOS)
			return .iOS
			#elseif os(tvOS)
			return .tvOS
			#else
			return .unknown
			#endif
		}()
	}
	#if !targetEnvironment(simulator)
	static func bootmanifestHash() -> String? {
		let registryEntry = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/chosen")
		
		guard let bootManifestHashUnmanaged = IORegistryEntryCreateCFProperty(registryEntry, "boot-manifest-hash" as CFString, kCFAllocatorDefault, 0),
			  let bootManifestHash = bootManifestHashUnmanaged.takeRetainedValue() as? Data else {
			return nil
		}
		
		return bootManifestHash.map { String(format: "%02X", $0) }.joined()
	}
	#endif
	static public func installation() -> jbStatus {
		#if targetEnvironment(simulator)
		return .simulated
		#else
		if paleInfo.palerain_option_rootful {
			return .rootful
		}

		if paleInfo.palerain_option_rootless {
			return .rootless
		}
		return .rootless
		#endif
	}
	
	static public func checkInstallStatus() -> installStatus {
		#if targetEnvironment(simulator)
		return .none
		#else
		if paleInfo.palerain_option_rootful {
			if FileManager.default.fileExists(atPath: "/.procursus_strapped") {
				return .rootful_installed
			}
		}

		if paleInfo.palerain_option_rootless {
			if FileManager.default.fileExists(atPath: "/var/jb/.procursus_strapped") {
				return .rootless_installed
			}

			if let bootManifestHash = bootmanifestHash() {
				let directoryPath = "/private/preboot/\(bootManifestHash)"
				let fileManager = FileManager.default
				
				do {
					let fileURLs = try fileManager.contentsOfDirectory(at: URL(fileURLWithPath: directoryPath), includingPropertiesForKeys: nil)
					let matchingFiles = fileURLs.filter { $0.lastPathComponent.hasPrefix("jb-") }
					
					if !matchingFiles.isEmpty {
						return .rootless_partial
					}
				} catch {
					print("Error accessing directory: \(error)")
				}
			}
		}
		
		return .none
		#endif
	}
}

