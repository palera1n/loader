//
//  Binpack.swift
//  palera1nLoader
//
//  Created by Staturnz on 6/11/23.
//

import Foundation

@discardableResult
public func helper(args: [String]) -> Int {
   return spawn(command: "/cores/binpack/usr/sbin/p1ctl", args: args)
}

class binpack {
    @discardableResult
    static public func rm(_ file: String) -> Int {
        return spawn(command: "/cores/binpack/bin/rm", args: ["-rf", file])
    }
    
    @discardableResult
    static public func mv(_ src: String,_ dest: String) -> Int {
        return spawn(command: "/cores/binpack/bin/ln", args: ["-s", src, dest])
    }
}
