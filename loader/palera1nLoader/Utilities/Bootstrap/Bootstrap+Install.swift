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
      let title: String = "\(LocalizationManager.shared.local("DOWNLOADING"))"
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
                                      let alert = UIAlertController.error(title: LocalizationManager.shared.local("DONE_INSTALL"), message: LocalizationManager.shared.local("DONE_INSTALL_SUB"))
                                      self.present(alert, animated: true)
                                  } else {
                                      let alert = UIAlertController.error(title: LocalizationManager.shared.local("ERROR_INSTALL"), message: "Status: \(errorString(Int32(error!)))")
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
                      let alert = UIAlertController.error(title: LocalizationManager.shared.local("DOWNLOAD_FAIL"), message: error.debugDescription)
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
                                      UIApplication.shared.openSpringBoard()
                                      exit(0)
                                  } else {
                                      let alert = UIAlertController.error(title: LocalizationManager.shared.local("ERROR_INSTALL"), message: "Status: \(errorString(Int32(error!)))")
                                      self.present(alert, animated: true)
                                  }
                              }
                          })
                      }
                  } else {
                      let alert = UIAlertController.error(title: LocalizationManager.shared.local("DOWNLOAD_FAIL"), message: error.debugDescription)
                      self.present(alert, animated: true)
                  }
              }
          }
      })
  }
}

class bootstrap {

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
        var prefix = ""
        if paleInfo.palerain_option_rootless { prefix = "/var/jb" }
        var ret = spawn(command: "\(prefix)/usr/bin/dpkg", args: ["-i", deb])
        if ret != 0 {
            log(type: .error, msg: String(format:"Failed to finalize bootstrap, installing libjbdrw failed with error code: \(ret)"))
        }

        ret = spawn(command: "/cores/binpack/usr/bin/uicache", args: ["-a"])
        if (ret != 0) {
            completion(LocalizationManager.shared.local("ERROR_UICACHE"), ret)
            return
        }
        
        cleanUp()
        completion(LocalizationManager.shared.local("DONE_INSTALL"), 0)
        return
    }
    
    
    static public func installBootstrap(tar: String, deb: String, completion: @escaping (String?, Int?) -> Void) {
        if (paleInfo.palerain_option_rootless) {
            binpack.rm("/var/jb")
        }
        let (deployBootstrap_ret, resultDescription) = DeployBootstrap(path: tar, password: "alpine");
     
        if (deployBootstrap_ret != 0) {
            log(msg: "Bootstrapper error occurred: \(resultDescription)")
            return
        }
        
        
        if Bootstrapper.needsFinalize() {
            log(msg: "Status: Finalizing Bootstrap")
            do {
                try Bootstrapper.finalizeBootstrap(deb: deb)
            } catch {
                log(msg: "Finalization error occurred: \(error)")
                return
            }
        }

        var ret = spawn(command: "/cores/binpack/usr/bin/uicache", args: ["-a"])
        if (ret != 0) {
            completion(LocalizationManager.shared.local("ERROR_UICACHE"), ret)
            return
        }
        
        ReloadLaunchdJailbreakEnvironment()
        
        cleanUp()
        completion(LocalizationManager.shared.local("DONE_INSTALL"), 0)
        return
    }
    
    static public func revert(viewController: UIViewController) -> Void {
        if paleInfo.palerain_option_rootless {
            let alert = UIAlertController.spinnerAlert("REMOVING")
            viewController.present(alert, animated: true)
            do {
                ObliterateJailbreak()
                ReloadLaunchdJailbreakEnvironment()
            }
            
            if (envInfo.rebootAfter) {
                spawn(command: "/cores/binpack/bin/launchctl", args: ["reboot"])
            } else {
                let errorAlert = UIAlertController.error(title: LocalizationManager.shared.local("DONE_REVERT"), message: LocalizationManager.shared.local("CLOSE_APP"))
                alert.dismiss(animated: true) {
                    viewController.present(errorAlert, animated: true)
                }
            }
        }
    }
}

