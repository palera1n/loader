#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

#define checkrain_option_safemode            (1 << 0)
#define checkrain_option_bind_mount          (1 << 1)
#define checkrain_option_overlay             (1 << 2)
#define checkrain_option_force_revert        (1 << 7) /* keep this at 7 */
    
#define palerain_option_rootful              (1 << 0) /* rootful jailbreak */
#define palerain_option_jbinit_log_to_file   (1 << 1) /* log to /cores/jbinit.log */
#define palerain_option_setup_rootful        (1 << 2) /* create fakefs */
#define palerain_option_setup_rootful_forced (1 << 3) /* create fakefs over an existing one */

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
        printf("[paleinfo] Size mismatch\n");
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
        printf("[paleinfo] Size mismatch\n");
        return -1;
    }
    if (info->magic != PALEINFO_MAGIC) {
        printf("[paleinfo] Detected corrupted paleinfo!\n");
        return -1;
    }
    if (info->version != 1) {
        printf("[paleinfo] Unsupported paleinfo %u (expected 1)\n", info->version);
        return -1;
    }
    close(fd);
    return 0;
}

int check_forcerevert(void) {
    struct kerninfo kinfo;
    int ret = get_kerninfo(&kinfo, "/dev/rmd0");
    if (ret != 0) {
        printf("[paleinfo] get_kerninfo() failed: %d\n", ret);
        return 0;
    }
    return (kinfo.flags & checkrain_option_force_revert) != 0;
}

int check_rootful(void) {
    struct paleinfo pinfo;
    int ret = get_paleinfo(&pinfo, "/dev/rmd0");
    if (ret != 0) {
        printf("[paleinfo] get_paleinfo() failed: %d\n", ret);
        return 1;
    }
    return (pinfo.flags & palerain_option_rootful) != 0;
}
