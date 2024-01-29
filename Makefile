TARGET_CODESIGN = $(shell which ldid)
GIT_REV=$(shell git rev-parse --short HEAD)



ifeq ($(IOS),1)
	PLATFORM = iphoneos
	NAME = palera1nLoader
	VOLNAME = loader
	RELEASE = Release-iphoneos
	ARG = ios=1
else ifeq ($(TVOS),1)
	PLATFORM = appletvos
	NAME = palera1nTVLoader
	VOLNAME = tvloader
	RELEASE = Release-tvos
	ARG = tv=1
else
$(error Please specify either IOS=1 or TVOS=1)
endif

MACOSX_SYSROOT = $(shell xcrun -sdk macosx --show-sdk-path)
TARGET_SYSROOT = $(shell xcrun -sdk $(PLATFORM) --show-sdk-path)
SED = gsed

ifeq ($(DEV),1)
	CONFIGURATION = Debug
else
	CONFIGURATION = Release
endif

P1_TMP         = $(TMPDIR)/$(NAME)
P1_STAGE_DIR   = $(P1_TMP)/stage
P1_APP_DIR 	   = $(P1_TMP)/Build/Products/$(RELEASE)/$(NAME).app

all: package

apple-include:
	mkdir -p apple-include/{bsm,objc,os/internal,sys,firehose,CoreFoundation,FSEvents,IOSurface,IOKit/kext,libkern,kern,arm,{mach/,}machine,CommonCrypto,Security,CoreSymbolication,Kernel/{kern,IOKit,libkern},rpc,rpcsvc,xpc/private,ktrace,mach-o,dispatch}
	cp -af $(MACOSX_SYSROOT)/usr/include/{arpa,bsm,hfs,net,xpc,netinet,servers,timeconv.h,launch.h} apple-include
	cp -af $(MACOSX_SYSROOT)/usr/include/objc/objc-runtime.h apple-include/objc
	cp -af $(MACOSX_SYSROOT)/usr/include/libkern/{OSDebug.h,OSKextLib.h,OSReturn.h,OSThermalNotification.h,OSTypes.h,machine} apple-include/libkern
	cp -af $(MACOSX_SYSROOT)/usr/include/kern apple-include
	cp -af $(MACOSX_SYSROOT)/usr/include/sys/{tty*,ptrace,kern*,random,reboot,user,vnode,disk,vmmeter,conf}.h apple-include/sys
	cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/Kernel.framework/Versions/Current/Headers/sys/disklabel.h apple-include/sys
	cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/{AppleConvergedIPCKeys.h,IOBSD.h,IOCFBundle.h,IOCFPlugIn.h,IOCFURLAccess.h,IOKitServer.h,IORPC.h,IOSharedLock.h,IOUserServer.h,audio,avc,firewire,graphics,hid,hidsystem,i2c,iokitmig.h,kext,ndrvsupport,network,ps,pwr_mgt,sbp2,scsi,serial,storage,stream,usb,video} apple-include/IOKit
	cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/Security.framework/Headers/{mds_schema,oidsalg,SecKeychainSearch,certextensions,Authorization,eisl,SecDigestTransform,SecKeychainItem,oidscrl,cssmcspi,CSCommon,cssmaci,SecCode,CMSDecoder,oidscert,SecRequirement,AuthSession,SecReadTransform,oids,cssmconfig,cssmkrapi,SecPolicySearch,SecAccess,cssmtpi,SecACL,SecEncryptTransform,cssmapi,cssmcli,mds,x509defs,oidsbase,SecSignVerifyTransform,cssmspi,cssmkrspi,SecTask,cssmdli,SecAsn1Coder,cssm,SecTrustedApplication,SecCodeHost,SecCustomTransform,oidsattr,SecIdentitySearch,cssmtype,SecAsn1Types,emmtype,SecTransform,SecTrustSettings,SecStaticCode,emmspi,SecTransformReadTransform,SecKeychain,SecDecodeTransform,CodeSigning,AuthorizationPlugin,cssmerr,AuthorizationTags,CMSEncoder,SecEncodeTransform,SecureDownload,SecAsn1Templates,AuthorizationDB,SecCertificateOIDs,cssmapple}.h apple-include/Security
	cp -af $(MACOSX_SYSROOT)/usr/include/{ar,bootstrap,launch,libc,libcharset,localcharset,nlist,NSSystemDirectories,tzfile,vproc}.h apple-include
	cp -af $(MACOSX_SYSROOT)/usr/include/mach/{*.defs,{mach_vm,shared_region}.h} apple-include/mach
	cp -af $(MACOSX_SYSROOT)/usr/include/mach/machine/*.defs apple-include/mach/machine
	cp -af $(MACOSX_SYSROOT)/usr/include/rpc/pmap_clnt.h apple-include/rpc
	cp -af $(MACOSX_SYSROOT)/usr/include/rpcsvc/yp{_prot,clnt}.h apple-include/rpcsvc
	cp -af $(TARGET_SYSROOT)/usr/include/mach/machine/thread_state.h apple-include/mach/machine
	cp -af $(TARGET_SYSROOT)/usr/include/mach/arm apple-include/mach
	cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/* apple-include/IOKit
	cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/IOSurface.framework/Headers/* apple-include/IOSurface
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/stdlib.h > apple-include/stdlib.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/time.h > apple-include/time.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/unistd.h > apple-include/unistd.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/task.h > apple-include/mach/task.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/mach_host.h > apple-include/mach/mach_host.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/ucontext.h > apple-include/ucontext.h
	$(SED) -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/signal.h > apple-include/signal.h
	$(SED) 's/#ifndef __OPEN_SOURCE__/#if 1\n#if defined(__has_feature) \&\& defined(__has_attribute)\n#if __has_attribute(availability)\n#define __API_AVAILABLE_PLATFORM_bridgeos(x) bridgeos,introduced=x\n#define __API_DEPRECATED_PLATFORM_bridgeos(x,y) bridgeos,introduced=x,deprecated=y\n#define __API_UNAVAILABLE_PLATFORM_bridgeos bridgeos,unavailable\n#endif\n#endif/g' < $(TARGET_SYSROOT)/usr/include/AvailabilityInternal.h > apple-include/AvailabilityInternal.h
	$(SED) -E /'__API_UNAVAILABLE'/d < $(TARGET_SYSROOT)/usr/include/pthread.h > apple-include/pthread.h
	$(SED) -iE 's| // __BLOCKS__|\n#include "$(TARGET_SYSROOT)/usr/include/bsm/audit.h"\n|' apple-include/xpc/connection.h
	@if [ -f $(TARGET_SYSROOT)/System/Library/Frameworks/CoreFoundation.framework/Headers/CFUserNotification.h ]; then $(SED) -E 's/API_UNAVAILABLE\(ios, watchos, tvos\)//g' < $(TARGET_SYSROOT)/System/Library/Frameworks/CoreFoundation.framework/Headers/CFUserNotification.h > apple-include/CoreFoundation/CFUserNotification.h; fi
	$(SED) -i -E s/'__API_UNAVAILABLE\(.*\)'// apple-include/IOKit/IOKitLib.h
	$(SED) -i -E s/'API_UNAVAILABLE(.*)'// apple-include/xpc/connection.h

package: apple-include
	/usr/libexec/PlistBuddy -c "Set :REVISION ${GIT_REV}" "loader/palera1nLoader/Info.plist"

	@set -o pipefail; \
		xcodebuild -jobs $(shell sysctl -n hw.ncpu) -project '$(VOLNAME)/palera1nLoader.xcodeproj' -scheme palera1nLoader -configuration $(CONFIGURATION) -arch arm64 -sdk $(PLATFORM) -derivedDataPath $(P1_TMP) \
		CODE_SIGNING_ALLOWED=NO DSTROOT=$(P1_TMP)/install ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO
	@rm -rf Payload
	@rm -rf $(P1_STAGE_DIR)/
	@mkdir -p $(P1_STAGE_DIR)/Payload
	@mv $(P1_APP_DIR) $(P1_STAGE_DIR)/Payload/$(NAME).app
	@echo $(P1_TMP)
	@echo $(P1_STAGE_DIR)

	@$(TARGET_CODESIGN) -Sentitlements.xml $(P1_STAGE_DIR)/Payload/$(NAME).app/
	
	@rm -rf $(P1_STAGE_DIR)/Payload/$(NAME).app/_CodeSignature
	@ln -sf $(P1_STAGE_DIR)/Payload Payload
	@rm -rf packages
	@mkdir -p packages

ifeq ($(TIPA),1)
	@zip -r9 packages/$(NAME).tipa Payload
else
	@zip -r9 packages/$(NAME).ipa Payload
endif
ifneq ($(NO_DMG),1)
	@hdiutil create loader.dmg -format UDZO -imagekey zlib-level=9 -layout NONE -volname "$(VOLNAME)" -fs HFS+ -ov -srcfolder Payload
endif
	@rm -rf Payload
	@rm -rf $(P1_TMP)

clean:
	@rm -rf $(P1_STAGE_DIR)
	@rm -rf packages
	@rm -rf out.dmg
	@rm -rf Payload
	@rm -rf apple-include
	@rm -rf $(P1_TMP)

.PHONY: apple-include
