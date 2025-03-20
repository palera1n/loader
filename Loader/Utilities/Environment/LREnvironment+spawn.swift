//
//  LREnvironment+spawn.swift
//  Loader
//
//  Created by samara on 13.03.2025.
//

import Foundation
import Darwin.POSIX

// MARK: - Class extension: spawn
extension LREnvironment {
	/// Executes a posix spawn command with a given environment path
	/// - Parameters:
	///   - command: Program path
	///   - args: Program arguments
	///   - environmentPath: Enviroment paths, such as `/usr/bin`
	/// - Returns: An exit status of the given command
	@discardableResult
	static func execute(
		_ command: String,
		_ args: [String] = [],
		environmentPath: [String]
	) -> Int {
		var path: String = "PATH="
		
		// Using the jailbreaks root prefix, we will prepend your paths with it
		// when specifying, you will need to only include the paths that will
		// be present on a standard filesystem such as /usr/bin, and NOT /var/jb/usr/bin
		let env = environmentPath.map {
			.jb_prefix($0)
		}.joined(separator: ":")
		path.append(env)
		
		return execute(command, args, environment: [path])
	}
	
	/// Executes a posix spawn command
	/// - Parameters:
	///   - command: Program path
	///   - args: Program arguments
	///   - environment: Environment variables, i.e. `VEE=1`
	/// - Returns: An exit status of the given command
	@discardableResult
	static func execute(
		_ command: String,
		_ args: [String] = [],
		environment: [String] = []
	) -> Int {
		#if targetEnvironment(simulator)
		return 0
		#else
		
		let cArgs = ([command] + args).map { strdup($0) } + [nil]
		
		defer {
			for arg in cArgs where arg != nil {
				free(arg)
			}
		}
		
		// we don't need a preset environment
		var env: [String] = []
		
		if !environment.isEmpty {
			for variable in environment {
				env.append(variable)
			}
		}
		
		let cEnv = env.map { strdup($0) } + [nil]
		
		defer {
			for e in cEnv where e != nil {
				free(e)
			}
		}
		
		var attr: posix_spawnattr_t?
		posix_spawnattr_init(&attr)
		
		posix_spawnattr_set_persona_np(&attr, 99, UInt32(POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE))
		posix_spawnattr_set_persona_uid_np(&attr, 0)
		posix_spawnattr_set_persona_gid_np(&attr, 0)
		
		var pid: pid_t = 0
		
		let status = posix_spawnp(&pid, command, nil, &attr, cArgs, cEnv)
		
		posix_spawnattr_destroy(&attr)
		
		if status != 0 {
			return Int(status)
		}
		
		var exitStatus: Int32 = 0
		waitpid(pid, &exitStatus, 0)
		
		// where the FUCK is WEXITSTATUS
		let exitCode = (exitStatus & 0xff00) >> 8
		// fucking xcode always makes this return 0??, I won't do anything about it, but be aware
		return Int(exitCode)
		#endif
	}
}
