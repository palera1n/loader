//
//  String+prefix.swift
//  Loader
//
//  Created by samara on 15.03.2025.
//

extension String {
	/// Returns a string with a jailbreak path prefix
	/// - Parameter path: Path
	/// - Returns: Path with prefix
	static func jb_prefix(_ path: String) -> String {
		LREnvironment.shared.jb_prefix(path)
	}
	/// Returns a string with a binpack path prefix
	/// - Parameter path: Path
	/// - Returns: Path with prefix
	static func binpack(_ path: String) -> String {
		LREnvironment.binpack(path)
	}
	/// Returns a string with a tmp path prefix
	/// - Parameter path: Path
	/// - Returns: Path with prefix
	static func tmp(_ path: String = "") -> String {
		LREnvironment.tmp(path)
	}
}
