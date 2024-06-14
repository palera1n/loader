//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#ifndef bridge_h
#define bridge_h

#include <spawn.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <stdint.h>
#include <mach-o/loader.h>
#include "jailbreakd.h"

const char* xpc_strerror(int err);
uint32_t dyld_get_active_platform(void);

#endif /* bridge_h */
