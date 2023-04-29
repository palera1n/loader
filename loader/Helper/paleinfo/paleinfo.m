#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import <IOKit/IOKitLib.h>

#define checkrain_option_safemode            (1 << 0) // 1
#define checkrain_option_bind_mount          (1 << 1) // 2
#define checkrain_option_overlay             (1 << 2) // 4
#define checkrain_option_force_revert        (1 << 7) /* keep this at 7 */ //128
    
#define palerain_option_rootful              (1 << 0) /* rootful jailbreak */ //1
#define palerain_option_jbinit_log_to_file   (1 << 1) /* log to /cores/jbinit.log */ // 2
#define palerain_option_setup_rootful        (1 << 2) /* create fakefs */ // 4
#define palerain_option_setup_rootful_forced (1 << 3) /* create fakefs over an existing one */ 8

#define PALEINFO_MAGIC 'PLSH'

struct paleinfo {
    uint32_t magic;
    int version;
    uint32_t flags;
    char rootdev[0x10];
};

struct kerninfo {
    uint64_t size;
    uint64_t base;
    uint64_t slide;
    uint32_t flags;
};

int get_kerninfo(struct kerninfo *info, char *rd) {
    uint32_t size = sizeof(struct kerninfo);
    uint32_t ramdisk_size_actual;
    int fd = open(rd, O_RDONLY, 0);
    read(fd, &ramdisk_size_actual, 4);
    lseek(fd, (long)(ramdisk_size_actual), SEEK_SET);
    int64_t didread = read(fd, info, sizeof(struct kerninfo));
    if ((unsigned long)didread != sizeof(struct kerninfo) || info->size != (uint64_t)sizeof(struct kerninfo)) {
        //NSLog(@"[paleinfo] Size mismatch\n");
        return -1;
    }
    if (info->size != size) return -1;
    close(fd);
    return 0;
}

int get_paleinfo(struct paleinfo *info, char *rd) {
    uint32_t ramdisk_size_actual;
    int fd = open(rd, O_RDONLY, 0);
    read(fd, &ramdisk_size_actual, 4);
    lseek(fd, (long)(ramdisk_size_actual) + 0x1000L, SEEK_SET);
    int64_t didread = read(fd, info, sizeof(struct paleinfo));
    if ((unsigned long)didread != sizeof(struct paleinfo)) {
        //NSLog(@"[paleinfo] Size mismatch\n");
        return -1;
    }
    if (info->magic != PALEINFO_MAGIC) {
        //NSLog(@"[paleinfo] Detected corrupted paleinfo!\n");
        return -1;
    }
    if (info->version != 1) {
        //NSLog(@"[paleinfo] Unsupported paleinfo %u (expected 1)\n", info->version);
        return -1;
    }
    close(fd);
    return 0;
}

int get_boot_manifest_hash(char hash[97]) {
#if TARGET_IPHONE_SIMULATOR
#else
    const UInt8 *bytes;
    CFIndex length;
    
    io_registry_entry_t chosen = IORegistryEntryFromPath(0, "IODeviceTree:/chosen");
    if (!MACH_PORT_VALID(chosen)) return 1;
    
    CFDataRef manifestHash = (CFDataRef)IORegistryEntryCreateCFProperty(chosen, CFSTR("boot-manifest-hash"), kCFAllocatorDefault, 0);
    IOObjectRelease(chosen);
    if (manifestHash == NULL || CFGetTypeID(manifestHash) != CFDataGetTypeID()) {
      if (manifestHash != NULL) CFRelease(manifestHash);
      return 1;
    }
    
    length = CFDataGetLength(manifestHash);
    bytes = CFDataGetBytePtr(manifestHash);
    for (int i = 0; i < length; i++) {
      snprintf(&hash[i * 2], 3, "%02X", bytes[i]);
    }
    
    CFRelease(manifestHash);
#endif
    return 0;
}

void get_pflags(void) {
    struct paleinfo pinfo;
    int ret = get_paleinfo(&pinfo, "/dev/rmd0");
    if (ret != 0) {
        //NSLog(@"[paleinfo] get_paleinfo() failed: %d\n", ret);
    }
    char buf[256];
    sprintf(buf, "%d\n", pinfo.flags);
    write(STDOUT_FILENO, &buf, strlen(buf) + 1);
}

void get_kflags(void) {
    struct kerninfo kinfo;
    int ret = get_kerninfo(&kinfo, "/dev/rmd0");
    if (ret != 0) {
        //NSLog(@"[paleinfo] get_kerninfo() failed: %d\n", ret);
    }
    char buf[256];
    sprintf(buf, "%d\n", kinfo.flags);
    write(STDOUT_FILENO, &buf, strlen(buf) + 1);
}

int get_bmhash(void) {
    char hash[97];
    int ret = get_boot_manifest_hash(hash);
    if (ret != 0) {
      //fprintf(stderr, "could not get boot manifest hash\n");
      return ret;
    }
    //printf("%s\n", hash);
 
    char buf[256];
    sprintf(buf, "%s\n", hash);
    write(STDOUT_FILENO, &buf, strlen(buf) + 1);
    return 0;
}

int check_forcerevert(void) {
    struct kerninfo kinfo;
    int ret = get_kerninfo(&kinfo, "/dev/rmd0");
    if (ret != 0) {
        //NSLog(@"[paleinfo] get_kerninfo() failed: %d\n", ret);
        return 0;
    }
   //NSLog(@"[paleinfo] kflags: %d\n", kinfo.flags);

    return (kinfo.flags & checkrain_option_force_revert) != 0;
}

int check_rootful(void) {
    struct paleinfo pinfo;
    int ret = get_paleinfo(&pinfo, "/dev/rmd0");
    if (ret != 0) {
        //NSLog(@"[paleinfo] get_paleinfo() failed: %d\n", ret);
        return 1;
    }
    //NSLog(@"[paleinfo] pflags: %d\n", pinfo.flags);

    return (pinfo.flags & palerain_option_rootful) != 0;
}
