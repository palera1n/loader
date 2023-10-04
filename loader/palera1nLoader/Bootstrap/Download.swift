//
//  Download.swift
//  palera1nLoader
//
//  Created by samara on 10/3/23.
//

import Foundation

extension JsonVC {
  func downloadFile(url: URL, forceBar: Bool = false, output: String? = nil, completion: @escaping (String?, Error?) -> Void) {
      let tempDir = URL(fileURLWithPath: "/tmp/")
      var destinationUrl = tempDir.appendingPathComponent(url.lastPathComponent)
      if (output != nil) {destinationUrl = tempDir.appendingPathComponent(output!)}

      let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
      var request = URLRequest(url: url)
      request.httpMethod = "GET"
      
      let task = session.dataTask(with: request, completionHandler: { data, response, error in
          if error == nil {
              if let response = response as? HTTPURLResponse {
                  if response.statusCode == 200 {
                      if let data = data {
                          if let _ = try? data.write(to: destinationUrl, options: Data.WritingOptions.atomic) {
                              completion("/tmp/\(destinationUrl.lastPathComponent)", error)
                              log(type: .info, msg: "Saved to: /tmp/\(destinationUrl.lastPathComponent)")
                          } else {
                              completion(destinationUrl.path, error)
                              log(type: .error, msg: "Failed to save file at: \(destinationUrl.path)")
                          }
                      } else {
                          completion(destinationUrl.path, error)
                          log(type: .error, msg: "Failed to download: \(request)")
                      }
                  } else {
                      completion(destinationUrl.path, error)
                      log(type: .error, msg: "Unknown error on download: \(response.statusCode) - \(request)")
                  }
              }
          } else {
              completion(destinationUrl.path, error)
              log(type: .error, msg: "Failed to download: \(request)")
          }
      })
      
      if (url.pathExtension == "zst" || url.pathExtension == "tar" || forceBar) {
          observation = task.progress.observe(\.fractionCompleted) { progress, _ in
              DispatchQueue.main.async {
                  progressDownload.setProgress(Float(progress.fractionCompleted/1.0), animated: true)
              }
          }
      }
      task.resume()
  }
}
