//
//  LSApplicationWorkspace.h
//  Loader
//
//  Created by samara on 13.03.2025.
//

#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <stdint.h>

@interface LSBundleProxy : NSObject
@property(nonatomic, assign, readonly) NSURL *bundleURL;
@property(nonatomic, assign, readonly) NSString *canonicalExecutablePath;
@end

@interface LSApplicationWorkspace
+ (instancetype)defaultWorkspace;
- (BOOL)openSensitiveURL:(NSURL *)url withOptions:(NSDictionary *)options;
- (BOOL)openURL:(NSURL *)url withOptions:(NSDictionary *)options;
- (BOOL)openApplicationWithBundleID:(NSString *)arg1;
@end
