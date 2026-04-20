#!/bin/bash
# Rift one-line installer
# Usage: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Papusha32/Rift/main/install.sh)"

set -e

REPO="Papusha32/Rift"
APP_NAME="Rift"
TMP_DMG="/tmp/Rift-installer.dmg"

# Colors
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
DIM='\033[2m'
RESET='\033[0m'

cleanup() {
    # Detach any mounted Rift volume silently
    hdiutil detach "/Volumes/$APP_NAME" -quiet 2>/dev/null || true
    rm -f "$TMP_DMG"
}
trap cleanup EXIT

echo ""
echo -e "${BOLD}Installing Rift…${RESET}"
echo ""

# 1. Fetch latest release URL
echo -e "${BLUE}→${RESET} Finding latest release"
DMG_URL=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
    | grep '"browser_download_url".*\.dmg"' \
    | head -1 \
    | sed -E 's/.*"(https:[^"]+)".*/\1/')

if [ -z "$DMG_URL" ]; then
    echo -e "${RED}✗${RESET} No release found on GitHub. Please try again later."
    exit 1
fi

# 2. Download DMG
echo -e "${BLUE}→${RESET} Downloading from ${DIM}$DMG_URL${RESET}"
curl -fL --progress-bar "$DMG_URL" -o "$TMP_DMG"

# 3. Quit any running Rift
if pgrep -x "$APP_NAME" > /dev/null 2>&1; then
    echo -e "${BLUE}→${RESET} Quitting running Rift"
    osascript -e "tell application \"$APP_NAME\" to quit" 2>/dev/null || true
    sleep 1
    pkill -x "$APP_NAME" 2>/dev/null || true
fi

# 4. Mount DMG
echo -e "${BLUE}→${RESET} Mounting DMG"
MOUNT=$(hdiutil attach "$TMP_DMG" -nobrowse -quiet | grep '/Volumes/' | head -1 | awk -F'\t' '{print $NF}')
if [ -z "$MOUNT" ]; then
    echo -e "${RED}✗${RESET} Failed to mount DMG"
    exit 1
fi

# 5. Copy to /Applications
echo -e "${BLUE}→${RESET} Installing to /Applications"
rm -rf "/Applications/$APP_NAME.app"
cp -R "$MOUNT/$APP_NAME.app" /Applications/

# 6. Remove quarantine (so macOS doesn't block unsigned app)
xattr -cr "/Applications/$APP_NAME.app"

# 7. Detach DMG
hdiutil detach "$MOUNT" -quiet 2>/dev/null || true

# 8. Launch
echo -e "${BLUE}→${RESET} Launching Rift"
open "/Applications/$APP_NAME.app"

echo ""
echo -e "${GREEN}✓${RESET} ${BOLD}Rift is installed and running.${RESET}"
echo -e "${DIM}  Look for the timer pill in your menu bar (top right of screen).${RESET}"
echo ""
