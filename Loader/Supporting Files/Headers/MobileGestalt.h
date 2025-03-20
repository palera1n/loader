/*
 * libMobileGestalt header.
 * Mobile gestalt functions as a QA system. You ask it a question, and it gives you the answer! :)
 *
 * Copyright (c) 2013-2014 Cykey (David Murray)
 * Improved by @PoomSmart (2020)
 * All rights reserved.
 */

#ifndef LIBMOBILEGESTALT_H_
#define LIBMOBILEGESTALT_H_

#include <CoreFoundation/CoreFoundation.h>

#if __cplusplus
extern "C" {
#endif

#pragma mark - API

CFPropertyListRef MGCopyAnswer(CFStringRef property);

#pragma mark - Device Information

static const CFStringRef kMGPhysicalHardwareNameString = CFSTR("PhysicalHardwareNameString");

#if __cplusplus
}
#endif

#endif /* LIBMOBILEGESTALT_H_ */
