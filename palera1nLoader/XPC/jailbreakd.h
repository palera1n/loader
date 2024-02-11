//
//  jailbreakd.h
//  palera1nLoader
//
//  Created by Nick Chan on 28/1/2024.
//

#ifndef jailbreakd_h
#define jailbreakd_h

#include <TargetConditionals.h>
#if !TARGET_OS_SIMULATOR
#include <stdio.h>
#include <xpc/xpc.h>
#include <bsm/audit.h>
#include <xpc/connection.h>
#include <stdarg.h>

#include <CoreFoundation/CoreFoundation.h>
#include <assert.h>
#ifndef __OBJC__
void NSLog(CFStringRef _Nonnull, ...);
void NSLogv(CFStringRef _Nonnull, va_list va);
#define LOG(x, ...) NSLog(CFSTR(x), ##__VA_ARGS__)
#endif

typedef xpc_object_t xpc_pipe_t;

__OSX_AVAILABLE_STARTING(__MAC_10_9, __IPHONE_7_0)
XPC_EXPORT XPC_NONNULL1 XPC_NONNULL2
kern_return_t
xpc_pipe_routine(xpc_pipe_t pipe, xpc_object_t request, xpc_object_t XPC_GIVES_REFERENCE *reply);

API_AVAILABLE(macos(12.0), ios(15.0), tvos(15.0), watchos(8.0))
XPC_EXPORT XPC_WARN_RESULT XPC_NONNULL1 XPC_NONNULL3 XPC_NONNULL4
int
_xpc_pipe_interface_routine(xpc_pipe_t pipe, uint64_t routine,
    xpc_object_t message, xpc_object_t XPC_GIVES_REFERENCE *reply,
    uint64_t flags);

struct _os_alloc_once_s {
    long once;
    void *ptr;
};

struct xpc_global_data {
    uint64_t    a;
    uint64_t    xpc_flags;
    mach_port_t    task_bootstrap_port;  /* 0x10 */
#ifndef _64
    uint32_t    padding;
#endif
    xpc_object_t    xpc_bootstrap_pipe;   /* 0x18 */
    // and there's more, but you'll have to wait for MOXiI 2 for those...
    // ...
};

extern struct _os_alloc_once_s _os_alloc_once_table[];

#define OS_ALLOC_ONCE_KEY_LIBXPC                    1



uint64_t GetPinfoFlags_impl(void);
char * _Nullable GetPrebootPath_impl(void);
int DeployBootstrap_impl(
                                 const char* _Nonnull bootstrap,
                                 bool no_password,
                                 const char* _Nullable password,
                                 const char* _Nonnull bootstrapper_name,
                                 const char* _Nonnull bootstrapper_version,
                                 char* _Null_unspecified * _Nonnull result_description
                         );

int OverwriteFile_impl(
                       const char* _Nonnull distinationPath,
                       const char* _Nonnull repositoriesContent,
                       char* _Null_unspecified * _Nonnull result_description
                       );

int ObliterateJailbreak_impl(void);
int GetPinfoKernelInfo_impl(uint64_t* kbase, uint64_t* kslide);
int ReloadLaunchdJailbreakEnvironment_impl(void);
int ExitFailureSafeMode_impl(void);
#endif

#endif /* jailbreakd_h */
