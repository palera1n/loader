#ifndef PALEINFO_H
#define PALEINFO_H
#include <unistd.h>

int check_forcerevert(void);
int check_rootful(void);
void get_pflags(void);
void get_kflags(void);
int get_bmhash(void);

#endif
