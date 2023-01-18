LDID           = $(shell command -v ldid)
STRIP          = $(shell command -v strip)

P1TMP          = $(TMPDIR)/palera1nloader
P1_STAGE_DIR   = $(P1TMP)/stage
P1_APP_DIR     = $(P1TMP)/Build/Products/Release-iphoneos/palera1nLoader.app
P1_HELPER_PATH = $(P1TMP)/Build/Products/Release-iphoneos/palera1nHelper

.PHONY: package

package:
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
	@$(LDID) -Sentitlements.plist $(P1_STAGE_DIR)/Payload/palera1nLoader.app/
	@$(LDID) -Sentitlements.plist $(P1_STAGE_DIR)/Payload/palera1nLoader.app/palera1nHelper
	
	@$(STRIP) $(P1_STAGE_DIR)/Payload/palera1nLoader.app/palera1nLoader
	@$(STRIP) $(P1_STAGE_DIR)/Payload/palera1nLoader.app/palera1nHelper
	
	@rm -rf $(P1_STAGE_DIR)/Payload/palera1nLoader.app/_CodeSignature

	@ln -sf $(P1_STAGE_DIR)/Payload Payload

	@rm -rf packages
	@mkdir -p packages

	@zip -r9 packages/palera1n.ipa Payload
	@rm -rf Payload
