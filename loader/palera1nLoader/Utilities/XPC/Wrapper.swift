//
//  Wrapper.swift
//  palera1nLoader
//
//  Created by Nick Chan on 28/1/2024.
//

import Foundation

#if targetEnvironment(simulator)
func GetPinfoFlags() -> UInt64 {
    return 0xc0002;
}
func GetPrebootPath() -> String? {
    return nil;
}
func DeployBootstrap(path: String, password: String) -> (Int, String) {
    return (0, "");
}
@discardableResult func ObliterateJailbreak() -> Int {
    return 0;
}
@discardableResult func ReloadLaunchdJailbreakEnvironment() -> Int {
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

func DeployBootstrap(path: String, password: String) -> (Int, String) {
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
    resultDescription.deallocate();
    return (Int(retval), result);
    
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

#endif
