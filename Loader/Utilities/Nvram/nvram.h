//
//  nvram.h
//  Loader
//
//  Created by samsam on 9/25/25.
//

#ifndef nvram_h
#define nvram_h

#include <IOKit/IOKitLib.h>

uint32_t nvram_set(char* key, char* value);

#endif
