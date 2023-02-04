#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>

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

static inline bool checkrain_option_enabled(checkrain_option_t flags, checkrain_option_t opt)
{
    return (flags & opt) != 0;
}

extern int get_rootful() {
    FILE *rd = fopen("/dev/rmd0", "rb");
    assert(rd != NULL);

    char *sizeBytes = malloc(sizeof(char) * 4);
    assert(sizeBytes != NULL);
    fread(sizeBytes, 1, 4, rd);

    uint32_t rdRealSize = *(uint32_t *)sizeBytes;

    printf("size is %d\n", rdRealSize);
    fseek(rd, rdRealSize + 0x5, SEEK_SET);

    char *dataRead = malloc(sizeof(struct paleinfo));
    assert(dataRead != NULL);
    fread(dataRead, 1, sizeof(struct paleinfo), rd);

    struct paleinfo *readStruct = (struct paleinfo *)dataRead;

    fclose(rd);
  
    return checkrain_option_enabled(readStruct->flags, palerain_option_rootful) ? 1 : 0;
}
