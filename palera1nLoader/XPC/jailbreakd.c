//
//  jailbreakd.c
//  palera1nLoader
//
//  Created by Nick Chan on 28/1/2024.
//

#include "jailbreakd.h"

#if !TARGET_OS_SIMULATOR

enum {
    JBD_CMD_GET_PINFO_FLAGS = 1,
    JBD_CMD_EXIT_SAFE_MODE = 10,
    JBD_CMD_GET_PREBOOTPATH,
    JBD_CMD_GET_PINFO_KERNEL_INFO,
    JBD_CMD_GET_PINFO_ROOTDEV,
    JBD_CMD_DEPLOY_BOOTSTRAP,
    JBD_CMD_OBLITERATE_JAILBREAK,
    JBD_CMD_PERFORM_REBOOT3,
    JBD_CMD_OVERWRITE_FILE_WITH_CONTENT,
};

enum {
    LAUNCHD_CMD_RELOAD_JB_ENV = 1,
    LAUNCHD_CMD_SET_TWEAKLOADER_PATH,
};

const char* xpc_strerror(int error);

static xpc_object_t jailbreak_send_jailbreakd_message_with_reply_sync(xpc_object_t xdict) {
    xpc_connection_t connection = xpc_connection_create_mach_service("in.palera.palera1nd.systemwide", NULL, 0);
    if (xpc_get_type(connection) == XPC_TYPE_ERROR) {
        return connection;
    }
    xpc_connection_set_event_handler(connection, ^(xpc_object_t _) {});
    xpc_connection_activate(connection);
    xpc_object_t xreply = xpc_connection_send_message_with_reply_sync(connection, xdict);
    xpc_connection_cancel(connection);
    xpc_release(connection);
    return xreply;
}

static xpc_object_t jailbreak_send_jailbreakd_command_with_reply_sync(uint64_t cmd) {
    xpc_object_t xdict = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_uint64(xdict, "cmd", cmd);
    xpc_object_t xreply = jailbreak_send_jailbreakd_message_with_reply_sync(xdict);
    xpc_release(xdict);
    return xreply;
}

static char* jailbreak_copy_jailbreakd_reply_description(xpc_object_t xreply) {
    const char* _Nullable errorDescription = xpc_dictionary_get_string(xreply, "errorDescription");
    const char* _Nullable message = xpc_dictionary_get_string(xreply, "message");
    int error = (int)xpc_dictionary_get_int64(xreply, "error");
    char* description = NULL;
    
    if (error || errorDescription) {
        if (error && !errorDescription) {
            asprintf(&description, "Error: %d (%s)", error, xpc_strerror(error));
        } else if (!error && errorDescription) {
            asprintf(&description, "Error: %s", errorDescription);
        } else if (error && errorDescription) {
            asprintf(&description, "Error: %s: %d (%s)", errorDescription, error, xpc_strerror(error));
        }
    } else if (message) {
        asprintf(&description, "%s", message);
    } else {
        asprintf(&description, "");
    }
    return description;
}

static int jailbreak_send_launchd_message(xpc_object_t xdict, xpc_object_t *xreply) {
    int ret = 0;
    xpc_dictionary_set_bool(xdict, "jailbreak", true);
    xpc_object_t bootstrap_pipe = ((struct xpc_global_data *)_os_alloc_once_table[OS_ALLOC_ONCE_KEY_LIBXPC].ptr)->xpc_bootstrap_pipe;
    if (__builtin_available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)) {
        ret = _xpc_pipe_interface_routine(bootstrap_pipe, 0, xdict, xreply, 0);
    } else {
        ret = xpc_pipe_routine(bootstrap_pipe, xdict, xreply);
    }
    //ret = xpc_pipe_routine(bootstrap_pipe, xdict, xreply);
    if (ret == 0 && (ret = (int)xpc_dictionary_get_int64(*xreply, "error")) == 0)
        return 0;

    return ret;
}

uint64_t GetPinfoFlags_impl(void) {
    xpc_object_t xreply = jailbreak_send_jailbreakd_command_with_reply_sync(JBD_CMD_GET_PINFO_FLAGS);
    if (xpc_get_type(xreply) == XPC_TYPE_ERROR) return 0;
    uint64_t pinfo = xpc_dictionary_get_uint64(xreply, "flags");
    xpc_release(xreply);
    return pinfo;
}

char * _Nullable GetPrebootPath_impl(void) {
    xpc_object_t xreply = jailbreak_send_jailbreakd_command_with_reply_sync(JBD_CMD_GET_PREBOOTPATH);
    if (xpc_get_type(xreply) == XPC_TYPE_ERROR) return 0;
    const char* path = xpc_dictionary_get_string(xreply, "path");
    char* retval;
    asprintf(&retval, "%s", path);
    xpc_release(xreply);
    return retval;
}

int DeployBootstrap_impl(
                                 const char bootstrap[],
                                 bool no_password,
                                 const char password[],
                                 const char bootstrapper_name[],
                                 const char bootstrapper_version[],
                                 char** result_description
                                 ) {
    xpc_object_t xdict = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_string(xdict, "path", bootstrap);
    xpc_dictionary_set_uint64(xdict, "cmd", JBD_CMD_DEPLOY_BOOTSTRAP);
    xpc_dictionary_set_string(xdict, "bootstrapper-name", bootstrapper_name);
    xpc_dictionary_set_string(xdict, "bootstrapper-version", bootstrapper_version);
    xpc_dictionary_set_bool(xdict, "no-password", no_password);
    if (!no_password) xpc_dictionary_set_string(xdict, "password", password);
    xpc_object_t xreply = jailbreak_send_jailbreakd_message_with_reply_sync(xdict);
    xpc_release(xdict);
    
    int retval = 0;
    
    if (xpc_get_type(xreply) == XPC_TYPE_ERROR) {
        retval = -1;
    } else {
        const char* errorDescription = xpc_dictionary_get_string(xreply, "errorDescription");
        int error = (int)xpc_dictionary_get_int64(xreply, "error");
        if (error) retval = error;
        else if (errorDescription) retval = -1;
        if (result_description) {
            char* description = jailbreak_copy_jailbreakd_reply_description(xreply);
            *result_description = description;
        }
        xpc_release(xreply);
    }
    return retval;
}
// MARK: - set repos
int OverwriteFile_impl(
                       const char* distinationPath,
                       const char* repositoriesContent,
                       char** result_description
                       ) {

    xpc_object_t xdict = xpc_dictionary_create(NULL, NULL, 0);
    xpc_dictionary_set_uint64(xdict, "cmd", JBD_CMD_OVERWRITE_FILE_WITH_CONTENT);
    xpc_dictionary_set_string(xdict, "path", distinationPath);

    size_t data_size = strlen(repositoriesContent);
    xpc_object_t data_object = xpc_data_create(repositoriesContent, data_size);
    xpc_dictionary_set_data(xdict, "data", xpc_data_get_bytes_ptr(data_object), xpc_data_get_length(data_object));

    xpc_object_t xreply = jailbreak_send_jailbreakd_message_with_reply_sync(xdict);
    xpc_release(xdict);
    xpc_release(data_object);

    int retval = 0;

    if (xpc_get_type(xreply) == XPC_TYPE_ERROR) {
        retval = -1;
    } else {
        const char* errorDescription = xpc_dictionary_get_string(xreply, "errorDescription");
        int error = (int)xpc_dictionary_get_int64(xreply, "error");
        if (error) retval = error;
        else if (errorDescription) retval = -1;
        if (result_description) {
            char* description = jailbreak_copy_jailbreakd_reply_description(xreply);
            *result_description = description;
        }
        xpc_release(xreply);
    }

    return retval;
}





int ObliterateJailbreak_impl(void) {
    xpc_object_t xreply = jailbreak_send_jailbreakd_command_with_reply_sync(JBD_CMD_OBLITERATE_JAILBREAK);
    if (xpc_get_type(xreply) == XPC_TYPE_ERROR) return -1;
    int error = (int)xpc_dictionary_get_int64(xreply, "error");
    xpc_release(xreply);
    if (error) return error;
    else return 0;
}

int GetPinfoKernelInfo_impl(uint64_t* kbase, uint64_t* kslide) {
    xpc_object_t xreply = jailbreak_send_jailbreakd_command_with_reply_sync(JBD_CMD_GET_PINFO_KERNEL_INFO);
    if (xpc_get_type(xreply) == XPC_TYPE_ERROR) return -1;
    int error = (int)xpc_dictionary_get_int64(xreply, "error");
    xpc_release(xreply);
    if (error) return error;
    *kbase = xpc_dictionary_get_uint64(xreply, "kbase");
    *kslide = xpc_dictionary_get_uint64(xreply, "kslide");
    return 0;
}

int ReloadLaunchdJailbreakEnvironment_impl(void) {
    xpc_object_t launchd_dict = xpc_dictionary_create(NULL, NULL, 0);
    xpc_object_t launchd_reply;
    xpc_dictionary_set_uint64(launchd_dict, "cmd", LAUNCHD_CMD_RELOAD_JB_ENV);
    int ret = jailbreak_send_launchd_message(launchd_dict, &launchd_reply);
    xpc_release(launchd_dict);
    xpc_release(launchd_reply);
    return ret;
}

int ExitFailureSafeMode_impl(void) {
    xpc_object_t xreply = jailbreak_send_jailbreakd_command_with_reply_sync(JBD_CMD_EXIT_SAFE_MODE);
    if (xpc_get_type(xreply) == XPC_TYPE_ERROR) return -1;
    int error = (int)xpc_dictionary_get_int64(xreply, "error");
    xpc_release(xreply);
    if (error) return error;
    else return 0;
}

#endif
