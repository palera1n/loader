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

P1_TMP         = $(TMPDIR)/$(NAME)
P1_STAGE_DIR   = $(P1_TMP)/stage
P1_APP_DIR 	   = $(P1_TMP)/Build/Products/$(RELEASE)/$(NAME).app
P1_HELPER_PATH = $(P1_TMP)/Build/Products/$(RELEASE)/Helper

package:
	/usr/libexec/PlistBuddy -c "Set :REVISION ${GIT_REV}" "loader/palera1nLoader/Info.plist"

	@set -o pipefail; \
		xcodebuild -jobs $(shell sysctl -n hw.ncpu) -project '$(VOLNAME)/palera1nLoader.xcodeproj' -scheme palera1nLoader -configuration Release -arch arm64 -sdk $(PLATFORM) -derivedDataPath $(P1_TMP) \
		CODE_SIGNING_ALLOWED=NO DSTROOT=$(P1_TMP)/install ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO
	@set -o pipefail; \
		xcodebuild -jobs $(shell sysctl -n hw.ncpu) -project '$(VOLNAME)/palera1nLoader.xcodeproj' -scheme Helper -configuration Release -arch arm64 -sdk $(PLATFORM) -derivedDataPath $(P1_TMP) \
		CODE_SIGNING_ALLOWED=NO DSTROOT=$(P1_TMP)/install ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO
	@rm -rf Payload
	@rm -rf $(P1_STAGE_DIR)/
	@mkdir -p $(P1_STAGE_DIR)/Payload
	@mv $(P1_APP_DIR) $(P1_STAGE_DIR)/Payload/$(NAME).app
	@echo $(P1_TMP)
	@echo $(P1_STAGE_DIR)

	@mv $(P1_HELPER_PATH) $(P1_STAGE_DIR)/Payload/$(NAME).app//Helper
	@$(TARGET_CODESIGN) -Sentitlements.xml $(P1_STAGE_DIR)/Payload/$(NAME).app/
	@$(TARGET_CODESIGN) -Sentitlements.xml $(P1_STAGE_DIR)/Payload/$(NAME).app//Helper
	
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
	@hdiutil create out.dmg -volname "$(VOLNAME)" -fs HFS+ -srcfolder Payload
	@hdiutil convert out.dmg -format UDZO -imagekey zlib-level=9 -o packages/$(VOLNAME).dmg
	@rm -rf out.dmg
endif
	@rm -rf Payload
	@rm -rf $(P1_TMP)

clean:
	@rm -rf $(P1_STAGE_DIR)
	@rm -rf packages
	@rm -rf out.dmg
	@rm -rf Payload
	@rm -rf $(P1_TMP)

