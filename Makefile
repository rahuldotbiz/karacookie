APP_NAME    := Karacookie
BUNDLE_ID   := com.karacookie.app
VERSION     := 1.0.0
BUILD_DIR   := .build
APP_BUNDLE  := $(BUILD_DIR)/$(APP_NAME).app
CONTENTS    := $(APP_BUNDLE)/Contents
MACOS_DIR   := $(CONTENTS)/MacOS
RES_DIR     := $(CONTENTS)/Resources

# Optional: export DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"
SIGN_IDENTITY ?= $(DEVELOPER_ID)

.PHONY: all build bundle run clean sign verify notarize dmg icon

all: bundle

build:
	swift build -c release --product $(APP_NAME)

bundle: build icon
	@rm -rf $(APP_BUNDLE)
	@mkdir -p $(MACOS_DIR) $(RES_DIR)
	@cp $(BUILD_DIR)/release/$(APP_NAME) $(MACOS_DIR)/$(APP_NAME)
	@cp Sources/$(APP_NAME)/Info.plist $(CONTENTS)/Info.plist
	@cp Resources/$(APP_NAME).icns $(RES_DIR)/$(APP_NAME).icns
	@printf 'APPL????' > $(CONTENTS)/PkgInfo
	@codesign --force --sign - \
		--entitlements Sources/$(APP_NAME)/$(APP_NAME).entitlements \
		$(APP_BUNDLE) 2>/dev/null || true
	@echo "Built $(APP_BUNDLE)"

icon:
	@if [ ! -f Resources/$(APP_NAME).icns ]; then \
		echo "Generating app icon…"; \
		swift tools/make-icon.swift; \
	fi

run: bundle
	open $(APP_BUNDLE)

sign: bundle
	@if [ -z "$(SIGN_IDENTITY)" ]; then \
		echo "Set DEVELOPER_ID, e.g.:"; \
		echo "  export DEVELOPER_ID=\"Developer ID Application: Your Name (TEAMID)\""; \
		exit 1; \
	fi
	codesign --force --options runtime --timestamp \
		--entitlements Sources/$(APP_NAME)/$(APP_NAME).entitlements \
		--sign "$(SIGN_IDENTITY)" \
		$(MACOS_DIR)/$(APP_NAME)
	codesign --force --options runtime --timestamp \
		--entitlements Sources/$(APP_NAME)/$(APP_NAME).entitlements \
		--sign "$(SIGN_IDENTITY)" \
		$(APP_BUNDLE)
	@codesign --verify --verbose=2 $(APP_BUNDLE)
	@spctl --assess --type execute --verbose=2 $(APP_BUNDLE) || true

verify:
	@codesign --verify --deep --strict --verbose=2 $(APP_BUNDLE) || true
	@spctl --assess --type execute --verbose=2 $(APP_BUNDLE) || true

# Requires: xcrun notarytool store-credentials AC_PASS  (one-time)
notarize: sign
	@cd $(BUILD_DIR) && ditto -c -k --keepParent $(APP_NAME).app $(APP_NAME).zip
	xcrun notarytool submit $(BUILD_DIR)/$(APP_NAME).zip \
		--keychain-profile AC_PASS --wait
	xcrun stapler staple $(APP_BUNDLE)

dmg: sign
	@command -v create-dmg >/dev/null || (echo "brew install create-dmg" && exit 1)
	create-dmg --volname "$(APP_NAME) $(VERSION)" \
		--window-size 540 320 --icon-size 96 \
		--app-drop-link 380 160 \
		$(BUILD_DIR)/$(APP_NAME)-$(VERSION).dmg $(APP_BUNDLE)

clean:
	swift package clean
	rm -rf $(APP_BUNDLE) $(BUILD_DIR)/$(APP_NAME).zip $(BUILD_DIR)/*.dmg
