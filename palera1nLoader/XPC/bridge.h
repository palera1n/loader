//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#ifndef bridge_h
#define bridge_h

#include <spawn.h>
#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <xpc/xpc.h>
#include "jailbreakd.h"

const char* xpc_strerror(int err);
static xpc_object_t jailbreak_send_jailbreakd_message_with_reply_sync(xpc_object_t xdict);

#endif /* bridge_h */
