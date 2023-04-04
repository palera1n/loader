TARGET_CODESIGN = $(shell which ldid)

POGOTMP = $(TMPDIR)/palera1nLoader
POGO_STAGE_DIR = $(POGOTMP)/stage
POGO_APP_DIR 	= $(POGOTMP)/Build/Products/Release-iphoneos/palera1nLoader.app
POGO_HELPER_PATH 	= $(POGOTMP)/Build/Products/Release-iphoneos/Helper
GIT_REV=$(shell git rev-parse --short HEAD)

package:
	/usr/libexec/PlistBuddy -c "Set :REVISION ${GIT_REV}" "palera1nLoader/Info.plist"

	@set -o pipefail; \
		xcodebuild -jobs $(shell sysctl -n hw.ncpu) -project 'palera1nLoader.xcodeproj' -scheme palera1nLoader -configuration Release -arch arm64 -sdk iphoneos -derivedDataPath $(POGOTMP) \
		CODE_SIGNING_ALLOWED=NO DSTROOT=$(POGOTMP)/install ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO
	@set -o pipefail; \
		xcodebuild -jobs $(shell sysctl -n hw.ncpu) -project 'palera1nLoader.xcodeproj' -scheme Helper -configuration Release -arch arm64 -sdk iphoneos -derivedDataPath $(POGOTMP) \
		CODE_SIGNING_ALLOWED=NO DSTROOT=$(POGOTMP)/install ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO
	@rm -rf Payload
	@rm -rf $(POGO_STAGE_DIR)/
	@mkdir -p $(POGO_STAGE_DIR)/Payload
	@mv $(POGO_APP_DIR) $(POGO_STAGE_DIR)/Payload/palera1nLoader.app

	@echo $(POGOTMP)
	@echo $(POGO_STAGE_DIR)

	@mv $(POGO_HELPER_PATH) $(POGO_STAGE_DIR)/Payload/palera1nLoader.app//Helper
	@$(TARGET_CODESIGN) -Sentitlements.xml $(POGO_STAGE_DIR)/Payload/palera1nLoader.app/
	@$(TARGET_CODESIGN) -Sentitlements.xml $(POGO_STAGE_DIR)/Payload/palera1nLoader.app//Helper
	
	@rm -rf $(POGO_STAGE_DIR)/Payload/palera1nLoader.app/_CodeSignature

	@ln -sf $(POGO_STAGE_DIR)/Payload Payload

	@rm -rf packages
	@mkdir -p packages

	@zip -r9 packages/palera1nLoader.ipa Payload
	@hdiutil create out.dmg -volname "loader" -fs HFS+ -srcfolder Payload
	@hdiutil convert out.dmg -format UDZO -imagekey zlib-level=9 -o packages/loader.dmg
	@rm -rf out.dmg
	@rm -rf Payload
