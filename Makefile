TARGET_CODESIGN = $(shell which ldid)
GIT_REV=$(shell git rev-parse --short HEAD)
STRIP = xcrun -sdk iphoneos strip

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

package:
	/usr/libexec/PlistBuddy -c "Set :REVISION ${GIT_REV}" "loader/palera1nLoader/Info.plist"

	@set -o pipefail; \
		xcodebuild -jobs $(shell sysctl -n hw.ncpu) -project '$(VOLNAME)/palera1nLoader.xcodeproj' -scheme palera1nLoader -configuration Release -arch arm64 -sdk $(PLATFORM) -derivedDataPath $(P1_TMP) \
		CODE_SIGNING_ALLOWED=NO DSTROOT=$(P1_TMP)/install ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO
	@rm -rf Payload
	@rm -rf $(P1_STAGE_DIR)/
	@mkdir -p $(P1_STAGE_DIR)/Payload
	@mv $(P1_APP_DIR) $(P1_STAGE_DIR)/Payload/$(NAME).app
	@echo $(P1_TMP)
	@echo $(P1_STAGE_DIR)

	@$(TARGET_CODESIGN) -Sentitlements.xml $(P1_STAGE_DIR)/Payload/$(NAME).app/$(NAME)
	@$(STRIP) $(P1_STAGE_DIR)/Payload/$(NAME).app/$(NAME)
ifneq ($(FINAL),1)
	/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier in.palera.loaderdebug" "$(P1_STAGE_DIR)/Payload/$(NAME).app/Info.plist"
	/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'palera1n (debug)'" "$(P1_STAGE_DIR)/Payload/$(NAME).app/Info.plist"
endif
	@rm -rf $(P1_STAGE_DIR)/Payload/$(NAME).app/_CodeSignature
	@ln -sf $(P1_STAGE_DIR)/Payload Payload
	@rm -rf packages
	@mkdir -p packages

ifeq ($(TIPA),1)
	@7zz a -mx=9 packages/$(NAME).tipa Payload
else
ifeq ($(FINAL),1)
	@sudo chmod 0755 Payload
	@sudo chmod 0755 Payload/palera1nLoader.app
	@sudo chown 501:0 Payload
	@sudo chown 501:0 Payload/palera1nLoader.app
	@sudo chmod 0755 Payload/palera1nLoader.app/*
	@sudo chmod 0644 Payload/palera1nLoader.app/Info.plist
	@sudo chmod 0644 Payload/palera1nLoader.app/PkgInfo
	@sudo chmod 0644 Payload/palera1nLoader.app/Assets.car
	@sudo chmod 0644 Payload/palera1nLoader.app/*.lproj/*
	@sudo chown 501:0 Payload/palera1nLoader.app/*
	@sudo chown 501:0 Payload/palera1nLoader.app/*.lproj/*
	@zip -r9 packages/$(NAME).ipa Payload
else
	@7zz a -mx=9 packages/$(NAME).ipa Payload
endif
endif
ifneq ($(NO_DMG),1)
	@sudo hdiutil create out.dmg -volname "$(VOLNAME)" -fs HFS+ -srcfolder Payload
	@sudo hdiutil convert out.dmg -format UDZO -imagekey zlib-level=9 -o packages/$(VOLNAME).dmg
	@sudo rm -rf out.dmg
endif
	@sudo rm -rf Payload
	@sudo rm -rf $(P1_TMP)

clean:
	@sudo rm -rf $(P1_STAGE_DIR)
	@sudo rm -rf packages
	@sudo rm -rf out.dmg
	@sudo rm -rf Payload
	@sudo rm -rf $(P1_TMP)

