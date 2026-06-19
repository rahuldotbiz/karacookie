#!/usr/bin/env bash
# Run this AFTER you've finished the Apple cert setup:
#   1. Developer ID Application cert installed in Keychain
#   2. `xcrun notarytool store-credentials AC_PASS` completed
#   3. `export DEVELOPER_ID="Developer ID Application: <Your Name> (TEAMID)"`
#
# Usage:  ./tools/ship-signed.sh 1.0.0

set -euo pipefail

VERSION="${1:?Usage: $0 <version>}"
APP_NAME="Karacookie"
ZIP_PATH=".build/${APP_NAME}-${VERSION}-mac.zip"
WEBSITE_DIR="/Users/r4/p0-rahul/www-rahul"
PAGE_PATH="${WEBSITE_DIR}/src/pages/karacookie/index.astro"

if [ -z "${DEVELOPER_ID:-}" ]; then
    cat <<EOF
✗ DEVELOPER_ID env var is not set.

  Find your cert string:
    security find-identity -v -p codesigning | grep "Developer ID Application"

  Then:
    export DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"

  And re-run:
    ./tools/ship-signed.sh ${VERSION}
EOF
    exit 1
fi

echo "▶ Signing + notarizing Karacookie ${VERSION}…"
make sign
make notarize

echo "▶ Creating distribution zip…"
cd .build
rm -f "${APP_NAME}-${VERSION}-mac.zip"
ditto -c -k --keepParent "${APP_NAME}.app" "${APP_NAME}-${VERSION}-mac.zip"
cd ..

echo "▶ Creating GitHub release v${VERSION}…"
gh release create "v${VERSION}" "${ZIP_PATH}" \
    --title "${APP_NAME} ${VERSION} — macOS (signed)" \
    --notes "$(cat <<NOTES
Signed and notarized. No Gatekeeper warning. Drop into /Applications, open, grant Automation permission, sing.

## Install
1. Download \`${APP_NAME}-${VERSION}-mac.zip\` below
2. Unzip, drag \`Karacookie.app\` to /Applications
3. Open — macOS asks: *"Karacookie wants to control Spotify"* → OK
4. Play any song. Lyrics flow.

— [karacookie page](https://rahul.biz/karacookie)
NOTES
)"

echo "▶ Bumping rahul.biz download link…"
if [ -f "${PAGE_PATH}" ]; then
    /usr/bin/sed -i '' "s|Karacookie-[0-9.]*-mac[^\"']*\.zip|${APP_NAME}-${VERSION}-mac.zip|g" "${PAGE_PATH}"
    /usr/bin/sed -i '' "s|releases/download/v[0-9.]*|releases/download/v${VERSION}|g" "${PAGE_PATH}"
    # Remove the "first open: right-click → Open" unsigned warning block
    /usr/bin/sed -i '' '/v0\.[12] is unsigned/,/signed v1\.0 dmg coming\./d' "${PAGE_PATH}" || true
    ( cd "${WEBSITE_DIR}" && git add src/pages/karacookie/index.astro && \
      git commit -m "karacookie: ship signed v${VERSION}" && git push )
fi

echo ""
echo "✓ Shipped v${VERSION} signed."
echo "  https://rahul.biz/karacookie"
echo "  https://github.com/rahuldotbiz/karacookie/releases/tag/v${VERSION}"
