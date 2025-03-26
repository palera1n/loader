//
//  Macros.h
//  Loader
//
//  Created by samara on 25.03.2025.
//

#ifndef Macros_h
#define Macros_h

#import <Foundation/Foundation.h>

NS_INLINE NSString* _Nonnull loaderConfigURL(void) CF_SWIFT_NAME(loaderConfigURL()) {
	return @CONFIG_URL;
}

NS_INLINE NSString* _Nonnull dotfilePath(void) CF_SWIFT_NAME(dotfilePath()) {
	return @DOTFILE_PATH;
}

#endif /* Macros_h */
