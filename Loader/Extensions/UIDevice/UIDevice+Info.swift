//
//  UIDevice+Info.swift
//  Loader
//
//  Created by samara on 9.03.2025.
//

import MachO
import UIKit.UIDevice

extension UIDevice {
	struct CFVersionInfo {
		private let _cfVersionNumber = kCFCoreFoundationVersionNumber
		
		var standard: String {
			return "\(Int(floor(_cfVersionNumber)))"
		}
		
		var rounded: String {
			return "\(Int(floor(_cfVersionNumber / 100) * 100))"
		}
	}
	
	var cfVersion: CFVersionInfo {
		return CFVersionInfo()
	}
	
	/// The devices architecture (e.g. arm64).
	var architecture: String {
		return String(cString: NXGetLocalArchInfo().pointee.name)
	}
	
	/// The devices marketing model (e.g. iPhone 7)
	var marketingModel: String {
		return MGCopyAnswer(kMGPhysicalHardwareNameString)?.takeUnretainedValue() as? String ?? "Unknown"
	}
	
	var kernelVersion: String {
		var utsnameInfo = utsname()
		uname(&utsnameInfo)
		
		let releaseCopy = withUnsafeBytes(of: &utsnameInfo.release) { bytes in
			Array(bytes)
		}
		
		let version = String(cString: releaseCopy)
		return version
	}
	
	var bootArgs: String {
		var size: size_t = 0
		sysctlbyname("kern.bootargs", nil, &size, nil, 0)
		var machine = [CChar](repeating: 0, count: size)
		sysctlbyname("kern.bootargs", &machine, &size, nil, 0)
		let bootArgs = String(cString: machine)
		return bootArgs
	}
	
	var bootmanifestHash: String? {
		#if !targetEnvironment(simulator)
		let registryEntry = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/chosen")
		
		guard let bootManifestHashUnmanaged = IORegistryEntryCreateCFProperty(registryEntry, "boot-manifest-hash" as CFString, kCFAllocatorDefault, 0),
			  let bootManifestHash = bootManifestHashUnmanaged.takeRetainedValue() as? Data else {
			return nil
		}
		
		return bootManifestHash.map { String(format: "%02X", $0) }.joined()
		#else
		return nil
		#endif
	}
}
