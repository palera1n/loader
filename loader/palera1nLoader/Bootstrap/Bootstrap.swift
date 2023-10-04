//
//  Bootstrap.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/12/23.
//

import Foundation
import UIKit

extension JsonVC {
  func installDebFile(file: String) {
      UIApplication.shared.isIdleTimerDisabled = true
      let title: String.LocalizationValue = "\(local("DOWNLOADING"))"
      let downloadAlert = UIAlertController.downloading(title)
      present(downloadAlert, animated: true)
      
      let downloadUrl = getManagerURL(envInfo.jsonInfo!, file)!

      downloadFile(url: URL(string: downloadUrl)!, forceBar: true, completion:{(path:String?, error:Error?) in
          DispatchQueue.main.async {
              downloadAlert.dismiss(animated: true) {
                  if (error == nil) {
                      let installingAlert = UIAlertController.spinnerAlert("INSTALLING")
                      self.present(installingAlert, animated: true) {
                          bootstrap.installDebian(deb: path!, completion:{(msg:String?, error:Int?) in
                              installingAlert.dismiss(animated: true) {
                                  if (error == 0) {
                                      let alert = UIAlertController.error(title: local("DONE_INSTALL"), message: local("DONE_INSTALL_SUB"))
                                      self.present(alert, animated: true)
                                  } else {
                                      let alert = UIAlertController.error(title: local("ERROR_INSTALL"), message: "Status: \(errorString(Int32(error!)))")
                                      self.present(alert, animated: true)
                                  }
                              }
                          })
                      }
                  } else {
                      let alert = UIAlertController.error(title: "Download Failed", message: error!.localizedDescription)
                      self.present(alert, animated: true)
                  }
              }
          }
      })
  }
  
  func installStrap(file: String, completion: @escaping () -> Void) {
      UIApplication.shared.isIdleTimerDisabled = true
      let downloadAlert = UIAlertController.downloading("DL_STRAP")
      present(downloadAlert, animated: true)

      let bootstrapUrl = getBootstrapURL(envInfo.jsonInfo!)!
      let pkgmgrUrl = getManagerURL(envInfo.jsonInfo!, file)!
      
      downloadFile(url: URL(string: pkgmgrUrl)!, completion:{(path:String?, error:Error?) in
          if (error != nil) {
              DispatchQueue.main.async {
                  downloadAlert.dismiss(animated: true) {
                      let alert = UIAlertController.error(title: local("DOWNLOAD_FAIL"), message: error.debugDescription)
                      self.present(alert, animated: true)
                  }
              }
          }
      })

      self.downloadFile(url:  URL(string: bootstrapUrl)!, completion:{(path:String?, error:Error?) in
          DispatchQueue.main.async {
              downloadAlert.dismiss(animated: true) {
                  if (error == nil) {
                      let installingAlert = UIAlertController.spinnerAlert("INSTALLING")
                      self.present(installingAlert, animated: true) {
                          bootstrap.installBootstrap(tar: path!, deb: "\(file).deb", completion:{(msg:String?, error:Int?) in
                              installingAlert.dismiss(animated: true) {
                                  if (error == 0) {
                                      let message = local("PASSWORD")
                                      let alertController = UIAlertController(title: local("PASSWORD_SET"), message: message, preferredStyle: .alert)
                                      alertController.addTextField() { (password) in
                                          password.placeholder = local("PASSWORD_TEXT")
                                          password.isSecureTextEntry = true
                                          password.keyboardType = UIKeyboardType.asciiCapable
                                      }

                                      alertController.addTextField() { (repeatPassword) in
                                          repeatPassword.placeholder = local("PASSWORD_REPEAT")
                                          repeatPassword.isSecureTextEntry = true
                                          repeatPassword.keyboardType = UIKeyboardType.asciiCapable
                                      }

                                      let setPassword = UIAlertAction(title: local("SET"), style: .default) { _ in
                                          helper(args: ["-P", alertController.textFields![0].text!])
                      
                                          alertController.dismiss(animated: true) {
                                              let alert = UIAlertController.error(title: local("DONE_INSTALL"), message: local("DONE_INSTALL_SUB"))
                                              self.present(alert, animated: true)
                                              completion()
                                          }
                                      }
                                      setPassword.isEnabled = false
                                      alertController.addAction(setPassword)

                                      NotificationCenter.default.addObserver(
                                          forName: UITextField.textDidChangeNotification,
                                          object: nil,
                                          queue: .main
                                      ) { notification in
                                          let passOne = alertController.textFields![0].text
                                          let passTwo = alertController.textFields![1].text
                                          if (passOne!.count > 253 || passOne!.count > 253) {
                                              setPassword.setValue(local("TOO_LONG"), forKeyPath: "title")
                                          } else {
                                              setPassword.setValue(local("SET"), forKeyPath: "title")
                                              setPassword.isEnabled = (passOne == passTwo) && !passOne!.isEmpty && !passTwo!.isEmpty
                                          }
                                      }
                                      self.present(alertController, animated: true)
                                  } else {
                                      let errStr = String(cString: strerror(Int32(error!)))
                                      let alert = UIAlertController.error(title: local("ERROR_INSTALL"), message: errStr)
                                      self.present(alert, animated: true)
                                  }
                              }
                          })
                      }
                  } else {
                      let alert = UIAlertController.error(title: local("DOWNLOAD_FAIL"), message: error.debugDescription)
                      self.present(alert, animated: true)
                  }
              }
          }
      })
  }
}

class bootstrap {

    // Ran after bootstrap/deb install
    static public func cleanUp() -> Void {
      let pathsToClear = ["/tmp/palera1n/temp"]
      for path in pathsToClear {
        let files = try! FileManager.default.contentsOfDirectory(atPath: path)
        for file in files {
          binpack.rm("\(path)/\(file)")
        }
      }
        let palera1nDir = try! FileManager.default.contentsOfDirectory(atPath: "/tmp/palera1n")
        for file in palera1nDir {
            if (file.contains("loader.log")) {
                binpack.rm("/tmp/palera1n/\(file)")
            }
        }

        URLCache.shared.removeAllCachedResponses()
        URLCache.shared.diskCapacity = 0
        URLCache.shared.memoryCapacity = 0
        
        do {
            let tmp = URL(string: NSTemporaryDirectory())!
            let tmpFile = try FileManager.default.contentsOfDirectory(at: tmp, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for url in tmpFile {try FileManager.default.removeItem(at: url)}}
        catch {
            return
        }
    }
    

    static public func installDebian(deb: String, completion: @escaping (String?, Int?) -> Void) {
        var ret = helper(args: ["-d", deb])
        if (ret != 0) {
            completion(local("DPKG_ERROR"), ret)
            return
        }

        ret = spawn(command: "/cores/binpack/usr/bin/uicache", args: ["-a"], root: true)
        if (ret != 0) {
            completion(local("ERROR_UICACHE"), ret)
            return
        }
        
        cleanUp()
        completion(local("DONE_INSTALL"), 0)
        return
    }
    
    
    static public func installBootstrap(tar: String, deb: String, completion: @escaping (String?, Int?) -> Void) {
        let debPath = "/tmp/\(deb)"
        var ret = helper(args: ["--install", tar, debPath])
        if (ret != 0) {
            completion(local("ERROR_STRAP"), ret)
            return
        }
        
        ret = spawn(command: "/cores/binpack/usr/bin/uicache", args: ["-a"], root: true)
        if (ret != 0) {
            completion(local("ERROR_UICACHE"), ret)
            return
        }
        
        cleanUp()
        completion(local("DONE_INSTALL"), 0)
        return
    }
    
    
    static public func revert(viewController: UIViewController) -> Void {
        if !envInfo.isRootful {
            let alert = UIAlertController.spinnerAlert("REMOVING")
            viewController.present(alert, animated: true)
            helper(args: ["-R"])
            
            if (envInfo.rebootAfter) {
                helper(args: ["-r"])
            } else {
                let errorAlert = UIAlertController.error(title: local("DONE_REVERT"), message: local("CLOSE_APP"))
                alert.dismiss(animated: true) {
                    viewController.present(errorAlert, animated: true)
                }
            }
        }
    }
}

