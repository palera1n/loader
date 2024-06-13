import Foundation
import Darwin.POSIX
import Bridge

let XPC_ARRAY_APPEND = -1;

@discardableResult func spawn(command: String, args: [String]) -> Int {
    var xdict = xpc_dictionary_create(nil, nil, 0);
    var xargv = xpc_array_create(nil, 0);
    var xenvp = xpc_array_create(nil, 0);
    xpc_dictionary_set_uint64(xdict, "cmd", UInt64(JBD_CMD_RUN_AS_ROOT));
    xpc_dictionary_set_string(xdict, "path", command);
    
    xpc_array_set_string(xargv, XPC_ARRAY_APPEND, command);
    for arg in args {
        xpc_array_set_string(xargv, XPC_ARRAY_APPEND, arg);
    }
    xpc_array_set_string(xenvp, XPC_ARRAY_APPEND, "PATH=/usr/local/sbin:/var/jb/usr/local/sbin:/usr/local/bin:/var/jb/usr/local/bin:/usr/sbin:/var/jb/usr/sbin:/usr/bin:/var/jb/usr/bin:/sbin:/var/jb/sbin:/bin:/var/jb/bin:/usr/bin/X11:/var/jb/usr/bin/X11:/usr/games:/var/jb/usr/games");
    xpc_array_set_string(xenvp, XPC_ARRAY_APPEND, "NO_PASSWORD_PROMPT=1");
    xpc_dictionary_set_value(xdict, "argv", xargv);
    xpc_dictionary_set_value(xdict, "envp", xenvp);
    
    var xreply = jailbreak_send_jailbreakd_message_with_reply_sync(xdict);
    defer { xpc_release(xreply!); }
    
    if (xpc_dictionary_get_int64(xdict, "error") != 0) {
        return Int(xpc_dictionary_get_int64(xdict, "error"));
    }

    return Int(xpc_dictionary_get_int64(xdict, "status"));
}
