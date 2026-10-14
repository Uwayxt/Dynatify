#!/bin/bash
# ==============================================================================
# Dynatify — Automated Installer for macOS
# Dynamic Island & Real-Time Synced Lyrics for Spotify & Apple Music
# Created by @uwayxt
# ==============================================================================

set -e

# Terminal Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo -e "${CYAN}${BOLD}"
echo "  ____                   _   _  __       "
echo " |  _ \ _   _ _ __   __ _| |_(_)/ _|_   _ "
echo " | | | | | | | '_ \ / _\` | __| | |_| | | |"
echo " | |_| | |_| | | | | (_| | |_| |  _| |_| |"
echo " |____/ \__, |_| |_|\__,_|\__|_|_|  \__, |"
echo "        |___/                       |___/ "
echo -e "${NC}"
echo -e "${BOLD}Dynatify Installer • by @uwayxt${NC}"
echo -e "Dynamic Island & Synced Lyrics for Spotify & Apple Music\n"

# Check macOS version
OS_VERSION=$(sw_vers -productVersion | cut -d. -f1)
if [ "$OS_VERSION" -lt 14 ]; then
    echo -e "${RED}Error: Dynatify requires macOS 14 (Sonoma) or newer.${NC}"
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_APP="/Applications/Dynatify.app"

echo -e "${CYAN}==>${NC} ${BOLD}1. Memeriksa proses yang sedang berjalan...${NC}"
if pgrep -x "Dynatify" > /dev/null; then
    echo -e "${YELLOW}   Menghentikan Dynatify yang sedang aktif...${NC}"
    pkill -x "Dynatify" 2>/dev/null || true
    sleep 1
fi

echo -e "${CYAN}==>${NC} ${BOLD}2. Mengompilasi Dynatify dengan Xcode...${NC}"
cd "$PROJECT_DIR/MelodyIsland"

xcodebuild -project MelodyIsland.xcodeproj \
    -scheme Dynatify \
    -configuration Debug \
    build \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    -quiet

DERIVED_APP=$(find ~/Library/Developer/Xcode/DerivedData/MelodyIsland-*/Build/Products/Debug -name "Dynatify.app" -type d | head -n 1)

if [ -z "$DERIVED_APP" ] || [ ! -d "$DERIVED_APP" ]; then
    echo -e "${RED}Error: Gagal menemukan file hasil kompilasi Dynatify.app.${NC}"
    exit 1
fi

echo -e "${CYAN}==>${NC} ${BOLD}3. Memasang Dynatify ke /Applications...${NC}"
rm -rf "$TARGET_APP"
cp -R "$DERIVED_APP" "$TARGET_APP"

# Clear quarantine flags and register with macOS LaunchServices for instant icon display
xattr -dr com.apple.quarantine "$TARGET_APP" 2>/dev/null || true
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f -R -trusted "$TARGET_APP" 2>/dev/null || true

echo -e "${GREEN}${BOLD}✔ Pemasangan Berhasil!${NC}"
echo -e "Dynatify telah terpasang di: ${BOLD}$TARGET_APP${NC}\n"

read -p "Apakah Anda ingin membuka Dynatify sekarang? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}==>${NC} Membuka Dynatify..."
    open "$TARGET_APP"
    echo -e "${GREEN}Dynatify siap digunakan! Tekan ⌥ Space untuk toggle Island.${NC}"
fi
