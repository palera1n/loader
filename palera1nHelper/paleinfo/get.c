#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <stdint.h>
#include <assert.h>

#define checkrain_option_safemode            (1 << 0)
#define checkrain_option_bind_mount          (1 << 1)
#define checkrain_option_overlay             (1 << 2)
#define checkrain_option_force_revert        (1 << 7) /* keep this at 7 */
    
#define palerain_option_rootful              (1 << 0) /* rootful jailbreak */
#define palerain_option_jbinit_log_to_file   (1 << 1) /* log to /cores/jbinit.log */
#define palerain_option_setup_rootful        (1 << 2) /* create fakefs */
#define palerain_option_setup_rootful_forced (1 << 3) /* create fakefs over an existing one */

typedef uint32_t checkrain_option_t, *checkrain_option_p;

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
    checkrain_option_t flags;
};

static inline bool checkrain_option_enabled(checkrain_option_t flags, checkrain_option_t opt)
{
    return (flags & opt) != 0;
}

int get_fr(void) {
    FILE *rd = fopen("/dev/rmd0", "rb");
    if (rd == NULL) {
        return 1;
    }

    fseek(rd, 0, SEEK_END);
    long size = ftell(rd);
    fseek(rd, 0, SEEK_SET);
    
    if (size < 0x1004) {
        return 1;
    }

    char *sizeBytes = malloc(sizeof(char) * 4);
    assert(sizeBytes != NULL);
    fread(sizeBytes, 1, 4, rd);

    uint32_t rdRealSize = *(uint32_t *)sizeBytes;

    printf("size is %d\n", rdRealSize);
    fseek(rd, rdRealSize, SEEK_SET);

    char *dataRead = malloc(sizeof(struct kerninfo));
    assert(dataRead != NULL);
    fread(dataRead, 1, sizeof(struct kerninfo), rd);

    struct kerninfo *readStruct = (struct kerninfo *)dataRead;

    int fr_enabled = checkrain_option_enabled(readStruct->flags, checkrain_option_force_revert) ? 1 : 0;

    fclose(rd);
    free(dataRead);
    free(sizeBytes);
  
    return fr_enabled;
}

int get_rootful(void) {
    FILE *rd = fopen("/dev/rmd0", "rb");
    if (rd == NULL) {
        return 1;
    }

    fseek(rd, 0, SEEK_END);
    long size = ftell(rd);
    fseek(rd, 0, SEEK_SET);
    
    if (size < 0x1004) {
        return 1;
    }

    char *sizeBytes = malloc(sizeof(char) * 4);
    assert(sizeBytes != NULL);
    fread(sizeBytes, 1, 4, rd);

    uint32_t rdRealSize = *(uint32_t *)sizeBytes;

    printf("size is %d\n", rdRealSize);
    fseek(rd, rdRealSize + 0x1000, SEEK_SET);

    char *dataRead = malloc(sizeof(struct paleinfo));
    assert(dataRead != NULL);
    fread(dataRead, 1, sizeof(struct paleinfo), rd);

    struct paleinfo *readStruct = (struct paleinfo *)dataRead;

    int rootful_enabled = checkrain_option_enabled(readStruct->flags, palerain_option_rootful) ? 1 : 0;

    fclose(rd);
    free(sizeBytes);
    free(dataRead);
  
    return rootful_enabled;
}