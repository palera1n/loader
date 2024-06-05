//
//  Post.swift
//  loader-rewrite
//
//  Created by samara on 2/4/24.
//

import Foundation
import UIKit

class Finalize {
    var delegate: BootstrapLabelDelegate?
	func finalizeBootstrap(debs: [String]?, basePath: ContentDetails?, completion: @escaping (String?) -> Void) {
		guard let debs = debs, !debs.isEmpty else {
			completion("No .deb files provided to finalize bootstrap.")
			return
		}
		#if !targetEnvironment(simulator)
		var prefix = ""
		if paleInfo.palerain_option_rootless { prefix = "/var/jb" }
		self.setRepositories(basePath: basePath) {_ in }
		

		var shit = ["-i"]
		shit+=debs
		let debRet = spawn(command: "\(prefix)/usr/bin/dpkg", args: shit)
		if debRet != 0 {
			log(type: .error, msg: "Failed to finalize bootstrap, error code: \(debRet)")
			completion("Failed to finalize bootstrap using dpkg, error code: \(debRet)")
			return
		}
		let uicacheRet = spawn(command: "/cores/binpack/usr/bin/uicache", args: ["-a"])
		if uicacheRet != 0 {
			log(type: .error, msg: "Failed to finalize bootstrap using uicache, error code: \(uicacheRet)")
			completion("Failed to run uicache, error code: \(uicacheRet)")
			return
		}
		#endif
		completion(nil)
	}
    
    func setRepositories(basePath: ContentDetails?, completion: @escaping (String?) -> Void) {
		guard let assetsInfo = basePath?.repositories else {
			return
		}

		let joinedString = assetsInfo.map { $0.description }.joined(separator: "\n")

        let sourcePath = paleInfo.palerain_option_rootless
        ? "/var/jb/etc/apt/sources.list.d/palera1n.sources"
        : "/etc/apt/sources.list.d/palera1n.sources"

		let (deployBootstrap_ret, _) = OverwriteFile(destination: sourcePath, content: joinedString)
        if deployBootstrap_ret != 0 {
			return
        }
    }
    
    func postManagerInstall(deb: String, completion: @escaping (String?) -> Void) {
        var prefix = ""
        if paleInfo.palerain_option_rootless { prefix = "/var/jb" }

        #if !targetEnvironment(simulator)
        let debRet = spawn(command: "\(prefix)/usr/bin/dpkg", args: ["-i", deb])
        if debRet != 0 {
			log(type: .fatal, msg: "Failed to finalize bootstrap, error code: \(debRet)")
			completion("Failed to run dpkg, error code: \(debRet)")
        }
        
		let uicacheRet = spawn(command: "/cores/binpack/usr/bin/uicache", args: ["-a"])
		if uicacheRet != 0 {
			log(type: .error, msg: "Failed to finalize bootstrap using uicache, error code: \(uicacheRet)")
			completion("Failed to run uicache, error code: \(uicacheRet)")
			return
		}
		#endif
		
		Go.cleanUp()
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
			UIApplication.prepareForExitAndSuspend()
		}
    }
}

extension Go {
    func attemptManagerInstall(file: String) {
		
		guard let fileUrl = URL(string: file) else {
			print("Invalid URL for the initial file.")
			return
		}
		
		self.downloadFile(url: fileUrl) { [weak self] filePath, error in
			if let error = error {
				print("Failed to download initial file: \(error)")
				return
			}
			self!.delegate?.updateBootstrapLabel(withText: .localized("Installing Packages"))
			
			DispatchQueue(label: "Install manager").async {
				Finalize().postManagerInstall(deb: filePath!) { _ in }
			}
		}
    }
}
