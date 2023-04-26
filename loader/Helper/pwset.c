//
//  pwset.c
//  Helper
//
//  Created by Staturnz on 4/25/23.
//

#include "pwset.h"
#include "paleinfo.h"
#include <string.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <spawn.h>

int setpw(char *pw) {
    int fd[2];
    char buf[256];

    const char *bin = check_rootful() == 1 ? "/usr/sbin/pw" : "/var/jb/usr/sbin/pw";
    char *arg[] = {"pw", "usermod", "501", "-h", "0", NULL};

    if (pipe(fd) == -1) {
        return 1;
    }
    
    sprintf(buf, "%s\n", pw);
    write(fd[1], &buf, strlen(buf) + 1);

    dup2(fd[0], STDIN_FILENO);
    close(fd[0]);
    close(fd[1]);
    
    pid_t pid;
    posix_spawn(&pid, bin, NULL, NULL, arg, NULL);
    
    return 0;
}


