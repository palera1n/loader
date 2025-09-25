//
//  nvram.c
//  Loader
//
//  Created by samsam on 9/25/25.
//

#include "nvram.h"
#include <stdio.h>

uint32_t nvram_set(char* key, char* value) {
	CFStringRef cfKey = CFStringCreateWithCString(kCFAllocatorDefault, key, kCFStringEncodingUTF8);
	CFStringRef cfValue = CFStringCreateWithCString(kCFAllocatorDefault, value, kCFStringEncodingUTF8);
	io_registry_entry_t nvram = IORegistryEntryFromPath(kIOMasterPortDefault, kIODeviceTreePlane ":/options");
	kern_return_t ret = IORegistryEntrySetCFProperty(nvram, cfKey, cfValue);
	printf("Set nvram %s=%s ret: %d\n", key, value, ret);
	ret = IORegistryEntrySetCFProperty(nvram, CFSTR("IONVRAM-FORCESYNCNOW-PROPERTY"), cfKey);
	printf("sync nvram ret: %d\n", ret);
	IOObjectRelease(nvram);
	if (cfValue) CFRelease(cfValue);
	CFRelease(cfKey);
	return ret;
}
