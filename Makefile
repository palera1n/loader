TARGET_CODESIGN = $(shell which ldid)
# gmake PLATFORM=appletvos SCHEME=palera1nLoaderTV
PLATFORM ?= iphoneos
SCHEME ?= palera1nLoader
NAME = palera1nLoader
RELEASE = Release-$(PLATFORM)
CONFIGURATION = Release
CUSTOM_INCLUDE_PATH = apple-include-$(PLATFORM)

MACOSX_SYSROOT = $(shell xcrun -sdk macosx --show-sdk-path)
TARGET_SYSROOT = $(shell xcrun -sdk $(PLATFORM) --show-sdk-path)

P1_TMP         = $(TMPDIR)/$(SCHEME)
P1_STAGE_DIR   = $(P1_TMP)/stage
P1_APP_DIR 	   = $(P1_TMP)/Build/Products/$(RELEASE)/$(SCHEME).app

all: package

$(CUSTOM_INCLUDE_PATH):
	mkdir -p $(CUSTOM_INCLUDE_PATH)/{bsm,objc,os/internal,sys,firehose,CoreFoundation,FSEvents,IOSurface,IOKit/kext,libkern,kern,arm,{mach/,}machine,CommonCrypto,Security,CoreSymbolication,Kernel/{kern,IOKit,libkern},rpc,rpcsvc,xpc/private,ktrace,mach-o,dispatch}
	cp -af $(MACOSX_SYSROOT)/usr/include/{arpa,bsm,hfs,net,xpc,netinet,servers,timeconv.h,launch.h} $(CUSTOM_INCLUDE_PATH)
	cp -af $(MACOSX_SYSROOT)/usr/include/objc/objc-runtime.h $(CUSTOM_INCLUDE_PATH)/objc
	cp -af $(MACOSX_SYSROOT)/usr/include/libkern/{OSDebug.h,OSKextLib.h,OSReturn.h,OSThermalNotification.h,OSTypes.h,machine} $(CUSTOM_INCLUDE_PATH)/libkern
	cp -af $(MACOSX_SYSROOT)/usr/include/kern $(CUSTOM_INCLUDE_PATH)
	cp -af $(MACOSX_SYSROOT)/usr/include/sys/{tty*,ptrace,kern*,random,reboot,user,vnode,disk,vmmeter,conf}.h $(CUSTOM_INCLUDE_PATH)/sys
	cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/Kernel.framework/Versions/Current/Headers/sys/disklabel.h $(CUSTOM_INCLUDE_PATH)/sys
	cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/{AppleConvergedIPCKeys.h,IOBSD.h,IOCFBundle.h,IOCFPlugIn.h,IOCFURLAccess.h,IOKitServer.h,IORPC.h,IOSharedLock.h,IOUserServer.h,audio,avc,firewire,graphics,hid,hidsystem,i2c,iokitmig.h,kext,ndrvsupport,network,ps,pwr_mgt,sbp2,scsi,serial,storage,stream,usb,video} $(CUSTOM_INCLUDE_PATH)/IOKit
	cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/Security.framework/Headers/{mds_schema,oidsalg,SecKeychainSearch,certextensions,Authorization,eisl,SecDigestTransform,SecKeychainItem,oidscrl,cssmcspi,CSCommon,cssmaci,SecCode,CMSDecoder,oidscert,SecRequirement,AuthSession,SecReadTransform,oids,cssmconfig,cssmkrapi,SecPolicySearch,SecAccess,cssmtpi,SecACL,SecEncryptTransform,cssmapi,cssmcli,mds,x509defs,oidsbase,SecSignVerifyTransform,cssmspi,cssmkrspi,SecTask,cssmdli,SecAsn1Coder,cssm,SecTrustedApplication,SecCodeHost,SecCustomTransform,oidsattr,SecIdentitySearch,cssmtype,SecAsn1Types,emmtype,SecTransform,SecTrustSettings,SecStaticCode,emmspi,SecTransformReadTransform,SecKeychain,SecDecodeTransform,CodeSigning,AuthorizationPlugin,cssmerr,AuthorizationTags,CMSEncoder,SecEncodeTransform,SecureDownload,SecAsn1Templates,AuthorizationDB,SecCertificateOIDs,cssmapple}.h $(CUSTOM_INCLUDE_PATH)/Security
	cp -af $(MACOSX_SYSROOT)/usr/include/{ar,bootstrap,launch,libc,libcharset,localcharset,nlist,NSSystemDirectories,tzfile,vproc}.h $(CUSTOM_INCLUDE_PATH)
	cp -af $(MACOSX_SYSROOT)/usr/include/mach/{*.defs,{mach_vm,shared_region}.h} $(CUSTOM_INCLUDE_PATH)/mach
	cp -af $(MACOSX_SYSROOT)/usr/include/mach/machine/*.defs $(CUSTOM_INCLUDE_PATH)/mach/machine
	cp -af $(MACOSX_SYSROOT)/usr/include/rpc/pmap_clnt.h $(CUSTOM_INCLUDE_PATH)/rpc
	cp -af $(MACOSX_SYSROOT)/usr/include/rpcsvc/yp{_prot,clnt}.h $(CUSTOM_INCLUDE_PATH)/rpcsvc
	cp -af $(TARGET_SYSROOT)/usr/include/mach/machine/thread_state.h $(CUSTOM_INCLUDE_PATH)/mach/machine
	cp -af $(TARGET_SYSROOT)/usr/include/mach/arm $(CUSTOM_INCLUDE_PATH)/mach
	cp -af $(MACOSX_SYSROOT)/System/Library/Frameworks/IOKit.framework/Headers/* $(CUSTOM_INCLUDE_PATH)/IOKit
	gsed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/stdlib.h > $(CUSTOM_INCLUDE_PATH)/stdlib.h
	gsed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/time.h > $(CUSTOM_INCLUDE_PATH)/time.h
	gsed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/unistd.h > $(CUSTOM_INCLUDE_PATH)/unistd.h
	gsed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/task.h > $(CUSTOM_INCLUDE_PATH)/mach/task.h
	gsed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/mach/mach_host.h > $(CUSTOM_INCLUDE_PATH)/mach/mach_host.h
	gsed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/ucontext.h > $(CUSTOM_INCLUDE_PATH)/ucontext.h
	gsed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/signal.h > $(CUSTOM_INCLUDE_PATH)/signal.h
	gsed -E s/'__IOS_PROHIBITED|__TVOS_PROHIBITED|__WATCHOS_PROHIBITED'//g < $(TARGET_SYSROOT)/usr/include/spawn.h > $(CUSTOM_INCLUDE_PATH)/spawn.h
	gsed -E /'__API_UNAVAILABLE'/d < $(TARGET_SYSROOT)/usr/include/pthread.h > $(CUSTOM_INCLUDE_PATH)/pthread.h
	gsed -i -E s/'__API_UNAVAILABLE\(.*\)'// $(CUSTOM_INCLUDE_PATH)/IOKit/IOKitLib.h
	gsed -i -E s/'__API_UNAVAILABLE\(.*\)'// $(CUSTOM_INCLUDE_PATH)/spawn.h
	gsed -i -E s/'API_UNAVAILABLE\(.*\)'// $(CUSTOM_INCLUDE_PATH)/xpc/*.h
	gsed -i 's|// __XPC_INDIRECT__|\n#include "$(TARGET_SYSROOT)/usr/include/bsm/audit.h"\n|' $(CUSTOM_INCLUDE_PATH)/xpc/connection.h

package: $(CUSTOM_INCLUDE_PATH)
	@rm -rf $(P1_TMP)
	@set -o pipefail; \
		xcodebuild -jobs $(shell sysctl -n hw.ncpu) -project '$(NAME).xcodeproj' -scheme $(SCHEME) -configuration $(CONFIGURATION) -arch arm64 -sdk $(PLATFORM) -derivedDataPath $(P1_TMP) \
		CODE_SIGNING_ALLOWED=NO DSTROOT=$(P1_TMP)/install ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO
	@rm -rf Payload
	@rm -rf $(P1_STAGE_DIR)/
	@mkdir -p $(P1_STAGE_DIR)/Payload
	@mv $(P1_APP_DIR) $(P1_STAGE_DIR)/Payload/$(SCHEME).app
	@echo $(P1_TMP)
	@echo $(P1_STAGE_DIR)

	@$(TARGET_CODESIGN) -Sloader.entitlements $(P1_STAGE_DIR)/Payload/$(SCHEME).app/

	@rm -rf $(P1_STAGE_DIR)/Payload/$(SCHEME).app/_CodeSignature
	@ln -sf $(P1_STAGE_DIR)/Payload Payload
	@rm -rf packages/$(SCHEME).*
	@mkdir -p packages

ifeq ($(TIPA),1)
	@zip -r9 packages/$(SCHEME).tipa Payload
else
	@zip -r9 packages/$(SCHEME).ipa Payload
endif

clean:
	@rm -rf $(P1_STAGE_DIR)
	@rm -rf packages
	@rm -rf out.dmg
	@rm -rf Payload
	@rm -rf $(CUSTOM_INCLUDE_PATH)
	@rm -rf $(P1_TMP)

.PHONY: $(CUSTOM_INCLUDE_PATH)

