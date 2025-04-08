//
//  Wrapper.swift
//  palera1nLoader
//
//  Created by Nick Chan on 28/1/2024.
//

import Foundation

final class JailbreakD {
	static func getFlags() -> UInt64 {
		#if targetEnvironment(simulator)
//		0xc0002 // rootless
		0xc0081 // rootful
		//return 0x1000000002c00082
		//return 0x2000000
		#else
		GetPinfoFlags_impl()
		#endif
	}
	
	static func getPrebootPath() -> String? {
		#if targetEnvironment(simulator)
		nil
		#else
		let cStr = GetPrebootPath_impl()
		if (cStr != nil) {
			let str = String(cString: cStr!)
			cStr?.deallocate()
			return str
		} else {
			return nil
		}
		#endif
	}
	
	static func deployBootstrap(with path: String, password: String) -> (Int, String) {
		#if targetEnvironment(simulator)
		return (0, "")
		#else
		var resultDescription: UnsafeMutablePointer<CChar>!;
		
		let retval = DeployBootstrap_impl(
			path, false,
			password,
			Bundle.appExecutable,
			"\(Bundle.appVersionShort) (\(Bundle.bundleVersion)",
			&resultDescription
		)
		
		let result: String;
		if (resultDescription != nil) {
			result = String(cString: resultDescription);
		} else {
			result = ""
		}
		
		resultDescription.deallocate();
		return (Int(retval), result);
		#endif
	}
	
	
	static func overwriteFile(with data: String, to destination: String) -> (Int, String) {
		#if targetEnvironment(simulator)
		return (0, "")
		#else
		var resultDescription: UnsafeMutablePointer<CChar>!
		
		let retval = OverwriteFile_impl(
			destination,
			data,
			&resultDescription
		)
		
		let result: String
		if resultDescription != nil {
			result = String(cString: resultDescription)
		} else {
			result = ""
		}
		
		resultDescription?.deallocate()
		return (Int(retval), result)
		#endif
	}
	
	@discardableResult
	static func obliterateJailbreak(cleanFakeFS: Bool) -> Int {
		#if targetEnvironment(simulator)
		0
		#else
		Int(ObliterateJailbreak_impl(cleanFakeFS));
		#endif
	}
	
	@discardableResult
	static func reloadLaunchdJailbreakEnvironment() -> Int {
		#if targetEnvironment(simulator)
		0
		#else
		Int(ReloadLaunchdJailbreakEnvironment_impl());
		#endif
	}
	
	@discardableResult
	static func exitFailureSafeMode() -> Int {
		#if targetEnvironment(simulator)
		0
		#else
		Int(ExitFailureSafeMode_impl());
		#endif
	}
}
