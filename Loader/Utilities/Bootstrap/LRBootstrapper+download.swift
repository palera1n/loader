//
//  LRBootstrapper+download.swift
//  Loader
//
//  Created by samara on 18.03.2025.
//

import Foundation

// MARK: - Class extension: download
extension LRBootstrapper: URLSessionDownloadDelegate {
	func download(_ urls: [URL], completion: @escaping ([String: Error?]) -> Void) {
		let sessionConfig = URLSessionConfiguration.default
		let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
		
		var results: [String: Error?] = [:]
		let group = DispatchGroup()
		
		for url in urls {
			group.enter()
			
			let tmp = URL(fileURLWithPath: .tmp())
			let destination = tmp.appendingPathComponent(url.lastPathComponent)
			
			if url.lastPathComponent.contains("tar") || url.lastPathComponent.contains("zst") {
				bootstrapFilePath = destination.relativePath
			} else {
				packageFilePaths.append(destination.relativePath)
			}
			
			let downloadTask = session.downloadTask(with: url)
			
			downloadCompletionHandlers[downloadTask] = { (path, error) in
				results[url.absoluteString] = error
				group.leave()
			}
			
			downloadTaskToDestinationMap[downloadTask] = destination
			
			downloadTask.resume()
		}
		
		group.notify(queue: .main) {
			completion(results)
		}
	}
	
	func urlSession(
		_ session: URLSession,
		downloadTask: URLSessionDownloadTask,
		didFinishDownloadingTo location: URL
	) {
		guard let destinationURL = downloadTaskToDestinationMap[downloadTask] else {
			downloadCompletionHandlers[downloadTask]?(nil, NSError(domain: "Download", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not find destination for task"]))
			return
		}
		
		let tmp = URL(fileURLWithPath: .tmp())
		let destination = tmp.appendingPathComponent(destinationURL.lastPathComponent)
		
		let fileManager = FileManager.default
		
		do {
			if fileManager.fileExists(atPath: destination.path) {
				try fileManager.removeItem(at: destination)
			}
			print("downloaded to \(location)")
			try fileManager.moveItem(at: location, to: destination)
			print("moved to \(destination)")
			downloadCompletionHandlers[downloadTask]?(destinationURL.path, nil)
		} catch {
			downloadCompletionHandlers[downloadTask]?(nil, error)
		}
		
	}
	
	func urlSession(
		_ session: URLSession,
		downloadTask: URLSessionDownloadTask,
		didWriteData bytesWritten: Int64,
		totalBytesWritten: Int64,
		totalBytesExpectedToWrite: Int64
	) {
		//
	}
}
