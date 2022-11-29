//
//  LSApplicationWorkspace.h
//  palera1nLoader
//
//  Created by Lakhan Lothiyi on 28/11/2022.
//

#ifndef LSApplicationWorkspace_h
#define LSApplicationWorkspace_h

#include <dirent.h>
#include <mach/mach.h>
#include <objc/runtime.h>

#import <Foundation/Foundation.h>

@interface LSApplicationWorkspace : NSObject
+ (id) defaultWorkspace;
- (BOOL) registerApplication:(id)application;
- (BOOL) unregisterApplication:(id)application;
- (BOOL) invalidateIconCache:(id)bundle;
- (BOOL) registerApplicationDictionary:(id)application;
- (BOOL) installApplication:(id)application withOptions:(id)options;
- (BOOL) _LSPrivateRebuildApplicationDatabasesForSystemApps:(BOOL)system internal:(BOOL)internal user:(BOOL)user;
@end

Class lsApplicationWorkspace = NULL;
LSApplicationWorkspace* workspace = NULL;

void uicache(void) {
    

    if(lsApplicationWorkspace == NULL || workspace == NULL) {
        lsApplicationWorkspace = (objc_getClass("LSApplicationWorkspace"));
        workspace = [lsApplicationWorkspace performSelector:@selector(defaultWorkspace)];
    }

    if ([workspace respondsToSelector:@selector(_LSPrivateRebuildApplicationDatabasesForSystemApps:internal:user:)]) {
        if (![workspace _LSPrivateRebuildApplicationDatabasesForSystemApps:YES internal:YES user:NO])
            printf("[ERROR]: failed to rebuild application databases\n");
        
    }
    
    if ([workspace respondsToSelector:@selector(invalidateIconCache:)]) {
        [workspace invalidateIconCache:nil];
    }
}


#endif /* LSApplicationWorkspace_h */
