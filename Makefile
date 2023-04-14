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

POGOTMP             = $(TMPDIR)/$(NAME)
POGO_STAGE_DIR      = $(POGOTMP)/stage
POGO_APP_DIR 	    = $(POGOTMP)/Build/Products/$(RELEASE)/$(NAME).app
POGO_HELPER_PATH 	= $(POGOTMP)/Build/Products/$(RELEASE)/Helper

package:
	/usr/libexec/PlistBuddy -c "Set :REVISION ${GIT_REV}" "loader/palera1nLoader/Info.plist"

	@set -o pipefail; \
		xcodebuild -jobs $(shell sysctl -n hw.ncpu) -project '$(VOLNAME)/palera1nLoader.xcodeproj' -scheme palera1nLoader -configuration Release -arch arm64 -sdk $(PLATFORM) -derivedDataPath $(POGOTMP) \
		CODE_SIGNING_ALLOWED=NO DSTROOT=$(POGOTMP)/install ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO
	@set -o pipefail; \
		xcodebuild -jobs $(shell sysctl -n hw.ncpu) -project '$(VOLNAME)/palera1nLoader.xcodeproj' -scheme Helper -configuration Release -arch arm64 -sdk $(PLATFORM) -derivedDataPath $(POGOTMP) \
		CODE_SIGNING_ALLOWED=NO DSTROOT=$(POGOTMP)/install ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO
	@rm -rf Payload
	@rm -rf $(POGO_STAGE_DIR)/
	@mkdir -p $(POGO_STAGE_DIR)/Payload
	@mv $(POGO_APP_DIR) $(POGO_STAGE_DIR)/Payload/$(NAME).app
	@echo $(POGOTMP)
	@echo $(POGO_STAGE_DIR)

	@mv $(POGO_HELPER_PATH) $(POGO_STAGE_DIR)/Payload/$(NAME).app//Helper
	@$(TARGET_CODESIGN) -Sentitlements.xml $(POGO_STAGE_DIR)/Payload/$(NAME).app/
	@$(TARGET_CODESIGN) -Sentitlements.xml $(POGO_STAGE_DIR)/Payload/$(NAME).app//Helper
	
	@rm -rf $(POGO_STAGE_DIR)/Payload/$(NAME).app/_CodeSignature
	@ln -sf $(POGO_STAGE_DIR)/Payload Payload
	@rm -rf packages
	@mkdir -p packages

ifeq ($(TIPA),1)
	@zip -r9 packages/$(NAME).tipa Payload
else
	@zip -r9 packages/$(NAME).ipa Payload
endif
ifneq ($(NO_DMG),1)
	@hdiutil create out.dmg -volname "$(VOLNAME)" -fs HFS+ -srcfolder Payload
	@hdiutil convert out.dmg -format UDZO -imagekey zlib-level=9 -o packages/$(VOLNAME).dmg
	@rm -rf out.dmg
endif
	@rm -rf Payload
	@rm -rf $(POGOTMP)

clean:
	@rm -rf $(POGO_STAGE_DIR)
	@rm -rf packages
	@rm -rf out.dmg
	@rm -rf Payload
	@rm -rf $(POGOTMP)

