//
//  palera1nBridging.h
//  palera1nLoader
//
//  Created by Lakhan Lothiyi on 12/11/2022.
//

#ifndef palera1nBridging_h
#define palera1nBridging_h
#include <spawn.h>

#define POSIX_SPAWN_PERSONA_FLAGS_OVERRIDE 1
int posix_spawnattr_set_persona_np(const posix_spawnattr_t* __restrict, uid_t, uint32_t);
int posix_spawnattr_set_persona_uid_np(const posix_spawnattr_t* __restrict, uid_t);
int posix_spawnattr_set_persona_gid_np(const posix_spawnattr_t* __restrict, uid_t);

#endif /* palera1nBridging_h */
