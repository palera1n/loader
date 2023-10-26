//
//  paleinfo.swift
//  palera1nLoader
//
//  Created by staturnz on 10/12/23.
//

import Foundation

public struct kerninfo {
    var size: UInt64
    var base: UInt64
    var slide: UInt64
    var flags: UInt32
};

public struct paleinfo {
    var magic: UInt32
    var version: UInt32
    var flags: UInt32
    var size: UInt64
    var rootdev: UInt64
    var padding: UInt64
};

// untested
public func get_paleinfo() -> paleinfo? {
    var ramdiskSize = UInt32()
    let fd = open("/dev/rmd", O_RDONLY, 0)
    defer { close(fd) }
    
    read(fd, &ramdiskSize, 4)
    lseek(fd, Int64(ramdiskSize) + 0x1000, SEEK_SET)
    
    let size = MemoryLayout<paleinfo>.size
    var info_ptr = malloc(size)
    if (read(fd, &info_ptr, size) != size) {
        log(type: .error, msg: "failed to read paleinfo")
        return nil
    }
    
    if let info = info_ptr?.load(as: paleinfo.self) {
        return info
    }
    return nil
}

// untested
public func get_kerninfo() -> kerninfo? {
    var ramdiskSize = UInt32()
    let fd = open("/dev/rmd", O_RDONLY, 0)
    defer { close(fd) }
    
    read(fd, &ramdiskSize, 4)
    lseek(fd, Int64(ramdiskSize) + 0x1000, SEEK_SET)
    
    let size = MemoryLayout<kerninfo>.size
    var info_ptr = malloc(size)
    if (read(fd, &info_ptr, size) != size) {
        log(type: .error, msg: "failed to read kerninfo")
        return nil
    }
    
    if let info = info_ptr?.load(as: kerninfo.self) {
        return info
    }
    return nil
}
