//
//  Wrapper.swift
//  palera1nLoader
//
//  Created by Nick Chan on 28/1/2024.
//

import Foundation
#if targetEnvironment(simulator)
func GetPinfoFlags() -> UInt64 {
    //return 0xc0002; // rootless
    return 0xc0081 // rootful
    //return 0x1000000002c00082
    //return 0x2000000

}
func GetPrebootPath() -> String? {
    return nil;
}
func DeployBootstrap(path: String, deb: String, password: String) -> (Int, String) {
    return (0, "");
}

func OverwriteFile(destination: String, content: String) -> (Int, String) {
    return (0, "");
}

@discardableResult func ObliterateJailbreak() -> Int {
    return 0;
}

@discardableResult func ReloadLaunchdJailbreakEnvironment() -> Int {
    return 0;
}

@discardableResult func ExitFailureSafeMode() -> Int {
    return 0;
}

#else

func GetPinfoFlags() -> UInt64 {
   return GetPinfoFlags_impl();
}

func GetPrebootPath() -> String? {
    let cStr = GetPrebootPath_impl();
    if (cStr != nil) {
        let str = String(cString: cStr!);
        cStr?.deallocate();
        return str;
    } else {
        return nil;
    }
}

func DeployBootstrap(path: String, deb: String, password: String) -> (Int, String) {
    let bootstrapperVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String;
    let bootstrapperName = Bundle.main.infoDictionary?["CFBundleExecutable"] as? String;
    var resultDescription: UnsafeMutablePointer<CChar>!;
    
    let retval = DeployBootstrap_impl(path, false, password, bootstrapperName!, bootstrapperVersion!, &resultDescription);
    let result: String;
    if (resultDescription != nil) {
        result = String(cString: resultDescription);
    } else {
        result = "";
    }
    do {
        try Finalize().finalizeBootstrap(deb: deb)
    } catch {
        log(type: .fatal, msg: "\(error.localizedDescription)")
    }
    resultDescription.deallocate();
    return (Int(retval), result);
}


func OverwriteFile(destination: String, content: String) -> (Int, String) {
    var resultDescription: UnsafeMutablePointer<CChar>!

    let retval = OverwriteFile_impl(destination, content, &resultDescription)
    let result: String
    if resultDescription != nil {
        result = String(cString: resultDescription)
    } else {
        result = ""
    }

    resultDescription?.deallocate()

    return (Int(retval), result)
}

@discardableResult func ObliterateJailbreak() -> Int {
    return Int(ObliterateJailbreak_impl());
}

func GetPinfoKernelInfo() -> (UInt64, UInt64) {
    var kbase: UInt64 = 0;
    var kslide: UInt64 = 0;
    GetPinfoKernelInfo_impl(&kbase, &kslide);
    return (kbase, kslide);
}

@discardableResult func ReloadLaunchdJailbreakEnvironment() -> Int {
    return Int(ReloadLaunchdJailbreakEnvironment_impl());
}

@discardableResult func ExitFailureSafeMode() -> Int {
    return Int(ExitFailureSafeMode_impl());
}

#endif
