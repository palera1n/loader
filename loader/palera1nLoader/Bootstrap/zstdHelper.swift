//
//  zstdHelper.swift
//  palera1nLoader
//
//  Created by staturnz on 10/4/23.
//

import Foundation
import libzstd

private func get_file_size(_ path: String) -> size_t {
    var st = stat()
    if (stat(path, &st) != 0) {
        log(type: .error, msg: "failed to stat file: \(String(cString: strerror(errno)))")
        return 0
    }
    
    let file_size: off_t = st.st_size
    if (file_size <= 0 && uintmax_t(file_size) >= SIZE_MAX) {
        log(type: .error, msg: "file size to large for size_t casting")
        return 0
    }
    
    return size_t(file_size)
}

private func load_file_malloc(_ path: String,_ buf_size: inout UnsafeMutablePointer<size_t>) -> UnsafeMutableRawPointer? {
    let file_size = get_file_size(path)
    buf_size.pointee = file_size
    
    let buf = malloc(buf_size.pointee)
    if (buf == nil) {
        log(type: .error, msg: "buf malloc failed")
        return nil
    }
    
    let in_file = fopen(path, "rb")
    defer { fclose(in_file) }
    if (in_file == nil) {
        log(type: .error, msg: "failed to open file: \(path) \(String(cString: strerror(errno)))")
        return nil
    }
    
    let read_size = fread(buf, 1, file_size, in_file)
    if (read_size != file_size) {
        log(type: .error, msg: "failed to read from file: \(path) \(String(cString: strerror(errno)))")
        return nil
    }
    return buf
}

public func decompress_zst(_ path: String,_ output: String) -> Bool {
    var zst_size = UnsafeMutablePointer<size_t>.allocate(capacity: 1)
    let zst_buf = load_file_malloc(path, &zst_size)
    
    let tar_size = ZSTD_getFrameContentSize(zst_buf, zst_size.pointee)
    if (tar_size == ZSTD_CONTENTSIZE_ERROR) {
        log(type: .fatal, msg: "file was not compressed using zstd")
        return false
    }
    if (tar_size == ZSTD_CONTENTSIZE_UNKNOWN) {
        log(type: .fatal, msg: "original size is unknown")
        return false
    }
    
    let tar_buf = malloc(size_t(tar_size))
    if (tar_buf == nil) {
        log(type: .fatal, msg: "buf malloc failed")
        return false
    }
    
    let decompress_size = ZSTD_decompress(tar_buf, size_t(tar_size), zst_buf, zst_size.pointee)
    if (ZSTD_isError(decompress_size) != 0) {
        log(type: .fatal, msg: "zstd error: \(String(cString: ZSTD_getErrorName(decompress_size)))");
        return false
    }
    if (decompress_size != tar_size) {
        log(type: .fatal, msg: "file size mismatch error")
        return false
    }
    
    let tar_file = fopen(output, "wb")
    if (tar_file == nil) {
        log(type: .fatal, msg: "failed to open output file")
        return false
    }
    
    fwrite(tar_buf, size_t(tar_size), 1, tar_file)
    fclose(tar_file)
    
    free(tar_buf)
    free(zst_buf)
    return true
}
