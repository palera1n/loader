//
//  Binpack.swift
//  palera1nLoader
//
//  Created by Staturnz on 6/11/23.
//

import Foundation

private func checkBinpack() -> Bool {
    return true
}

@discardableResult
public func helper(args: [String]) -> Int {
   return spawn(command: "/tmp/palera1n/helper", args: args, root: true)
}

class binpack {
    
    @discardableResult
    static public func ln(_ src: String,_ dest: String) -> Int {
        if (checkBinpack()) {
            return spawn(command: "/cores/binpack/bin/ln", args: ["-s", src, dest], root: true)
        } else {
            log(type: .error, msg: "Failed to access binpack.")
            return -1
        }
    }
    
    @discardableResult
    static public func rm(_ file: String) -> Int {
        if (checkBinpack()) {
            return spawn(command: "/cores/binpack/bin/rm", args: ["-rf", file], root: true)
            
        } else {
            log(type: .error, msg: "Failed to access binpack.")
            return -1
        }
    }
    
    @discardableResult
    static public func mv(_ src: String,_ dest: String) -> Int {
        if (checkBinpack()) {
            return spawn(command: "/cores/binpack/bin/ln", args: ["-s", src, dest], root: true)
        } else {
            log(type: .error, msg: "Failed to access binpack.")
            return -1
        }
    }
    
}
