//
//  Untar.swift
//  palera1nLoader
//
//  Created by staturnz on 10/4/23.
//

import Foundation

let REGTYPE:        Int = 48   // regular file
let AREGTYPE:       Int = 0    // regular file
let LNKTYPE:        Int = 49   // link
let SYMTYPE:        Int = 50   // reserved
let CHRTYPE:        Int = 51   // character special
let BLKTYPE:        Int = 52   // block special
let DIRTYPE:        Int = 53   // directory
let FIFOTYPE:       Int = 54   // FIFO special

let NAME_OFF:       Int = 0    // name[100] offset
let MODE_OFF:       Int = 100  // mode[8] offset
let UID_OFF:        Int = 108  // uid[8] offset
let GID_OFF:        Int = 116  // gid[8] offset
let TYPEFLAG_OFF:   Int = 156  // typeflag offset
let LINKNAME_OFF:   Int = 157  // linkname[100] offset
let OCTAL_OFF:      Int = 103  // mode[8] += 3 offset
let MTIME_OFF:      Int = 136  // mtime[12] offset

let SYM:            Int = 1    // create symlink
let HARD:           Int = 0    // create hardlink

private class parse {
    @discardableResult
    static func mode(_ str: UnsafePointer<Int8>,_ mode: UnsafeMutablePointer<mode_t>) -> Int32 {
        var end: UnsafeMutablePointer<CChar>?
        mode.pointee = mode_t(strtol(str, &end, 8))
        if (end == nil) { return 0 }
        while (isspace(Int32(end!.pointee)) != 0) { end! += 1 }
        return (end!.pointee == 0) && (UInt(mode.pointee) < 010000) ? 1 : 0
    }
    
    @discardableResult
    static func oct(_ p: UnsafePointer<Int8>, _ n: size_t) -> Int32 {
        var i: Int32 = 0
        var p = p
        var n = n
        while ((p.pointee < 48 || p.pointee > 55) && n > 0) { p += 1; n -= 1 }
        while ((p.pointee >= 48 && p.pointee <= 55) && n > 0) {
            i *= 8; i += Int32(p.pointee) - 48; p += 1; n -= 1
        }
        return i
    }
    
    @discardableResult
    static func time(_ mtime: UnsafePointer<Int8>) -> time_t {
        var sz: size_t = 12
        var time: Int64 = 0
        var mtime = mtime
        while ((mtime.pointee < 48 || mtime.pointee > 55) && sz > 0) { mtime += 1; sz -= 1 }
        while ((mtime.pointee >= 48 && mtime.pointee <= 55) && sz > 0) {
            time *= 8; time += Int64(mtime.pointee) - 48; mtime += 1; sz -= 1
        }
        let epoch = time_t(time)
        return epoch
    }
}


private class util {
    @discardableResult
    static func get_uid(_ buff: UnsafePointer<Int8>) -> uid_t {
        return uid_t(parse.oct(buff + UID_OFF, 8))
    }
    
    @discardableResult
    static func get_gid(_ buff: UnsafePointer<Int8>) -> gid_t {
        return gid_t(parse.oct(buff + GID_OFF, 8))
    }
    
    @discardableResult
    static func get_mode(_ buff: UnsafePointer<Int8>, _ mode: inout mode_t) -> mode_t {
        return mode_t(parse.mode(buff + OCTAL_OFF, &mode))
    }
    
    @discardableResult
    static func set_time(_ pathName: UnsafePointer<Int8>, _ mtime: time_t, _ link: Int32) -> Int32 {
        var val = [timeval](repeating: timeval(), count: 2)
        val[0].tv_sec = mtime
        val[0].tv_usec = 0
        val[1].tv_sec = mtime
        val[1].tv_usec = 0

        if (link == 0) { return utimes(pathName, val) }
        return lutimes(pathName, val)
    }
    
    static func filter(_ path: String) -> Bool {
        let filename = URL(string: path)?.lastPathComponent
        let list = [
            "DS_Store", "PaxHeaders", "PaxHeader", "__MACOSX", ".Spotlight-V100", ".Trashes",
            "._", ".fseventsd", ".DocumentRevisions-V100", ".localized", ".TemporaryItems",
            "LIBARCHIVE.xattr"
        ]
        
        if (filename == nil) { return false }
        for item in list {if filename!.contains(item) { return true }}
        return false
    }
    
    static func archive_end(_ p: UnsafePointer<Int8>) -> Bool {
        for i in (0..<512).reversed() { if (p[i] != 0) { return false } }
        return true
    }

    static func verify_checksum(_ p: UnsafePointer<Int8>) -> Bool {
        var u: Int32 = 0
        for i in 0..<512 {
            if (i < 148 || i > 155) {
                u += Int32(Int(Int32(bitPattern: UInt32(bitPattern: Int32(p[i]))) & 0xFF))
            } else {
                u += 0x20
            }
        }
        return u == parse.oct(p + 148, 8)
    }
}

private class create {
    static func dir(_ pathname: UnsafeMutablePointer<Int8>, _ mode: mode_t, _ uid: uid_t, _ gid: gid_t) -> Void {
        if (util.filter(String(cString: pathname))) { return }
        let len = strlen(pathname)
        if (pathname[Int(len) - 1] == 47) {
            pathname[Int(len) - 1] = 0
        }
        var r = mkdir(pathname, mode)
        chown(pathname, uid, gid)

        if (r != 0) {
            let p = strrchr(pathname, 47)
            if (p != nil) {
                p!.pointee = 0
                create.dir(pathname, mode, uid, gid)
                p!.pointee = 47
                r = mkdir(pathname, mode)
                chown(pathname, uid, gid)
            }
        }
        if (r != 0) {
            if (strcmp(&pathname[1], ".") == 0) {
                log(type: .error, msg: "could not create directory: \(pathname)")
                return
            }
        }
    }
    
    @discardableResult
    static func file(_ pathname: UnsafeMutablePointer<Int8>, _ mode: mode_t, _ owner: uid_t, _ group: gid_t) -> UnsafeMutablePointer<FILE>? {
        if (util.filter(String(cString: pathname))) {
            log(type: .error, msg: "Skipping file: \(String(cString: pathname))")
            return nil
        }
        var f: UnsafeMutablePointer<FILE>? = fopen(pathname, "wb+")
        if (f == nil) {
            let p = strrchr(pathname, 47)
            if (p != nil) {
                p!.pointee = 0
                create.dir(pathname, mode, owner, group)
                p!.pointee = 47
                f = fopen(pathname, "wb+")
            }
        }
        return f
    }
    
    @discardableResult
    static func link(_ buff: UnsafeMutablePointer<Int8>, _ type: Int8) -> Int32 {
        var linkname = [CChar](repeating: 0, count: 100)
        var ret: Int32

        for n in 0..<100 { linkname[n] = buff[157 + n] }
        print(String(cString: linkname), "->", String(cString: buff))

        if (type == SYMTYPE) { ret = symlink(linkname, buff) }
        else { ret = Darwin.link(linkname, buff) }
        if (ret != 0) {
            log(type: .error, msg: "Failed to create link: \(String(cString: linkname)) (\(ret))")
            return ret
        }

        ret = util.set_time(buff, parse.time(buff + MTIME_OFF), 1)
        if (ret != 0) {
            log(type: .error, msg: "Failed to set mtime: \(String(cString: linkname)) (\(ret))")
            return ret
        }

        return 0
    }
}


public func untar(_ tar: String,_ output: String) -> Bool {
    var path_name = [Int8](repeating: 0, count: 100)
    var buff = [Int8](repeating: 0, count: 512)
    var new_file: UnsafeMutablePointer<FILE>? = nil

    var bytes_read: Int = 0
    var file_size: Int32 = 0
    var mtime: time_t = 0
    var mode: mode_t = 0
    var mode_print: Int = 0
    var tmp: Int32 = 0

    chmod(tar, 777)
    chown(tar, 0, 0)
    chdir(output)

    let tar_file = fopen(tar, "rb")
    if (tar_file == nil) {
        print("Failed to open tar file")
        return false
    }

    log(type: .error, msg: "extracting bootstrap to: \(output)")
    while true {
        bytes_read = Int(fread(&buff, 1, 512, tar_file))

        if (bytes_read < 512) {
            log(type: .error, msg: "short read on \(tar): expected 512, got \(bytes_read)")
            fclose(tar_file)
            return false
        }
        
        if (util.archive_end(&buff)) {
            log(type: .error, msg: "end of \(tar)")
            fclose(tar_file)
            return true
        }
        
        if (!util.verify_checksum(&buff)) {
            log(type: .error, msg: "checksum failure")
            fclose(tar_file)
            return false
        }
        
        file_size = buff.withUnsafeBufferPointer { bufferPointer in
            return parse.oct(bufferPointer.baseAddress! + 124, 12)
        }
        
        switch Int(buff[TYPEFLAG_OFF]) {
        case LNKTYPE, SYMTYPE:
            create.link(&buff, buff[TYPEFLAG_OFF])
        case CHRTYPE, BLKTYPE, FIFOTYPE:
            break
        case DIRTYPE:
            util.get_mode(&buff, &mode)
            mode_print = Int(String(mode, radix: 8))!
            create.dir(&buff, mode, util.get_uid(&buff), util.get_gid(&buff))
            file_size = 0
        default:
            print(String(cString: buff))
            mtime = buff.withUnsafeBytes { ptr in
                if let baseAddress = ptr.baseAddress?.advanced(by: MTIME_OFF).assumingMemoryBound(to: CChar.self) {
                    return parse.time(baseAddress)
                } else {
                   return time_t(NSDate().timeIntervalSince1970)
                }
            }

            tmp = buff.withUnsafeMutableBytes { ptr in
                parse.mode(ptr.bindMemory(to: CChar.self).baseAddress! + OCTAL_OFF, &mode)
            }
            mode_print = Int(String(mode, radix: 8))!
            for n in 0..<100 {
                path_name[n] = buff[0 + n]
            }
            
            new_file = create.file(&buff, mode, util.get_uid(&buff), util.get_gid(&buff))
            chown(path_name, util.get_uid(&buff), util.get_gid(&buff))
            break
        }

        while file_size > 0 {
            bytes_read = Int(fread(&buff, 1, 512, tar_file))
            if (bytes_read < 512) {
                log(type: .error, msg: "short read on \(tar): expected 512, got \(bytes_read)")
                fclose(tar_file)
                return false
            }
            
            if (file_size < 512) {
                bytes_read = Int(file_size)
            }
            
            if (new_file != nil) {
                if (fwrite(&buff, 1, bytes_read, new_file) != bytes_read) {
                    log(type: .error, msg: "failed write to: \(String(cString: buff))")
                    fclose(new_file)
                    new_file = nil
                }
            }
            file_size -= Int32(bytes_read)
        }

        if (new_file != nil) {
            fclose(new_file)
            chmod(path_name, mode)
            util.set_time(path_name, mtime, 0)
            new_file = nil
        }
    }
}

