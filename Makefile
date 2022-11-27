TARGET_CODESIGN = $(shell command -v ldid)

P1TMP          = $(TMPDIR)/palera1nloader
P1_REQUIRED    = palera1nLoader/Required
P1_STAGE_DIR   = $(P1TMP)/stage
P1_APP_DIR 	   = $(P1TMP)/Build/Products/Release-iphoneos/palera1nLoader.app
P1_HELPER_PATH = $(P1TMP)/Build/Products/Release-iphoneos/palera1nHelper

.PHONY: package

package:
	# Deps
	@rm -rf $(P1_REQUIRED)/*.deb
	
	curl -sL https://static.palera.in/libswift.deb -o $(P1_REQUIRED)/libswift.deb

	curl -sL https://static.palera.in/substitute.deb -o $(P1_REQUIRED)/substitute.deb

	curl -sL https://static.palera.in/safemode.deb -o $(P1_REQUIRED)/safemode.deb

	curl -sL https://static.palera.in/preferenceloader.deb -o $(P1_REQUIRED)/preferenceloader.deb
	
	curl -sL https://static.palera.in/sileo.deb -o $(P1_REQUIRED)/sileo.deb
	
	# Build
	@set -o pipefail; \
		xcodebuild -jobs $(shell sysctl -n hw.ncpu) -project 'palera1nLoader.xcodeproj' -scheme palera1nLoader -configuration Release -arch arm64 -sdk iphoneos -derivedDataPath $(P1TMP) \
		CODE_SIGNING_ALLOWED=NO DSTROOT=$(P1TMP)/install ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO
		
	@set -o pipefail; \
		xcodebuild -jobs $(shell sysctl -n hw.ncpu) -project 'palera1nLoader.xcodeproj' -scheme palera1nHelper -configuration Release -arch arm64 -sdk iphoneos -derivedDataPath $(P1TMP) \
		CODE_SIGNING_ALLOWED=NO DSTROOT=$(P1TMP)/install ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES=NO
	
	@rm -rf Payload
	@rm -rf $(P1_STAGE_DIR)/
	@mkdir -p $(P1_STAGE_DIR)/Payload
	@mv $(P1_APP_DIR) $(P1_STAGE_DIR)/Payload/palera1nLoader.app

	# Package
	@echo $(P1TMP)
	@echo $(P1_STAGE_DIR)

	@mv $(P1_HELPER_PATH) $(P1_STAGE_DIR)/Payload/palera1nLoader.app/palera1nHelper
	@$(TARGET_CODESIGN) -Sentitlements.plist $(P1_STAGE_DIR)/Payload/palera1nLoader.app/
	@$(TARGET_CODESIGN) -Sentitlements.plist $(P1_STAGE_DIR)/Payload/palera1nLoader.app/palera1nHelper
	
	@rm -rf $(P1_STAGE_DIR)/Payload/palera1nLoader.app/_CodeSignature

	@ln -sf $(P1_STAGE_DIR)/Payload Payload

	@rm -rf packages
	@mkdir -p packages

	@cp -r $(P1_REQUIRED)/* $(P1_STAGE_DIR)/Payload/palera1nLoader.app

	@zip -r9 packages/palera1n.ipa Payload
	@rm -rf Payload
