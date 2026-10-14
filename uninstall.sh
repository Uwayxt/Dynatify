#!/bin/bash
# ==============================================================================
# Dynatify — Clean Uninstaller for macOS
# Created by @uwayxt
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${RED}${BOLD}"
echo "  _   _       _           _        _ _ "
echo " | | | |_ __ (_)_ __  ___| |_ __ _| | |"
echo " | | | | '_ \| | '_ \/ __| __/ _\` | | |"
echo " | |_| | | | | | | | \__ \ || (_| | | |"
echo "  \___/|_| |_|_|_| |_|___/\__\__,_|_|_|"
echo -e "${NC}"
echo -e "${BOLD}Dynatify Uninstaller • by @uwayxt${NC}\n"

echo -e "${YELLOW}Tindakan ini akan menghapus Dynatify dan membersihkan seluruh preferensinya.${NC}"
read -p "Apakah Anda yakin ingin menghapus Dynatify? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${CYAN}Proses pembatalan uninstall.${NC}"
    exit 0
fi

echo -e "\n${CYAN}==>${NC} 1. Menghentikan proses Dynatify & background daemon..."
if pgrep -x "Dynatify" > /dev/null; then
    pkill -x "Dynatify" 2>/dev/null || true
    echo "   • Dynatify dihentikan."
fi

# Stop bridge if running
if [ -f "/tmp/dynatify_bridge.pid" ]; then
    BRIDGE_PID=$(cat "/tmp/dynatify_bridge.pid" 2>/dev/null || true)
    if [ -n "$BRIDGE_PID" ]; then
        kill "$BRIDGE_PID" 2>/dev/null || true
    fi
    rm -f /tmp/dynatify_* 2>/dev/null || true
    echo "   • Bridge daemon dibersihkan."
fi

echo -e "${CYAN}==>${NC} 2. Menghapus /Applications/Dynatify.app..."
if [ -d "/Applications/Dynatify.app" ]; then
    rm -rf "/Applications/Dynatify.app"
    echo "   • /Applications/Dynatify.app berhasil dihapus."
else
    echo "   • /Applications/Dynatify.app tidak ditemukan."
fi

echo -e "${CYAN}==>${NC} 3. Membersihkan preferensi dan cache pengguna..."
defaults delete com.uwayxt.Dynatify 2>/dev/null || true
rm -rf "$HOME/Library/Preferences/com.uwayxt.Dynatify.plist" 2>/dev/null || true
rm -rf "$HOME/Library/Application Support/Dynatify" 2>/dev/null || true
rm -rf "$HOME/Library/Caches/com.uwayxt.Dynatify" 2>/dev/null || true

echo -e "\n${GREEN}${BOLD}✔ Dynatify telah berhasil dihapus sepenuhnya dari sistem Anda.${NC}"
echo -e "Terima kasih telah mencoba Dynatify • by @uwayxt\n"
