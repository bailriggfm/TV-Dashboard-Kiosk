#!/bin/bash
set -e

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# CONFIG
ISO_LABEL="ArchLinux-Kiosk"
ISO1_EXEC='ExecStart=/usr/bin/cage -s -- /usr/bin/firefox --profile "/home/live/.mozilla/firefox/m1j0kl8f.kiosk_profile" --kiosk --no-remote --start-fullscreen --no-proxy-server "https://screen.bailriggfm.co.uk/view/office?pass=primary"'
ISO2_EXEC='ExecStart=/usr/bin/cage -s -- /usr/bin/firefox --profile "/home/live/.mozilla/firefox/m1j0kl8f.kiosk_profile" --kiosk --no-remote --start-fullscreen --no-proxy-server "https://screen.bailriggfm.co.uk/view/studio-a"'
USERPASSWORD="liveuser"

# Do not change these unless you have changed the coressponding files.
CONFIG_DIR="./"
TARGET_FILE="${CONFIG_DIR}/airootfs/etc/systemd/system/cage@.service"
USERNAME="live"           # User to update
USERPASSWORDHASH=$(echo "$USERPASSWORD" | openssl passwd -6 -stdin) # Generate a password with a random salt
SHADOW_FILE="./airootfs/etc/shadow"  # Path to your shadow file

# Save original line
ORIGINAL_LINE=$(grep '^ExecStart=' "$TARGET_FILE")
echo "✅ Original line backed up: $ORIGINAL_LINE"

# Replace line
echo "🔧 Patching line for ISO 1..."
sed -i "s|^ExecStart=.*|$ISO1_EXEC|" "$TARGET_FILE"

echo "🔧 Patching shadow file for ISO 1..."
sed -i "s|^$USERNAME:[^:]*:|$USERNAME:$USERPASSWORDHASH:|" "$SHADOW_FILE"

# Build first ISO
echo "▶️ Building first ISO..."
mkarchiso -v -w ../work-iso1 -o ../out-iso1 "$CONFIG_DIR"

# Replace line
echo "🔧 Patching line for ISO 2..."
sed -i "s|^ExecStart=.*|$ISO2_EXEC|" "$TARGET_FILE"

# Build second ISO
echo "▶️ Building second ISO (with modified line)..."
mkarchiso -v -w ../work-iso2 -o ../out-iso2 "$CONFIG_DIR"

# Restore original line
echo "♻️ Restoring original config..."
sed -i "s|^ExecStart=.*|$ORIGINAL_LINE|" "$TARGET_FILE"
sed -i "s|^$USERNAME:[^:]*:|$USERNAME:CHANGE_ME:|" "$SHADOW_FILE"

echo "🔧 Moving ISO"
# Get current build date in YYYY-MM-DD format
ISO_BUILD_DATE=$(date +%F)
mkdir -p ./build
mv ../out-iso1/ArchLinux-Kiosk*.iso "./build/ArchLinux-Kiosk-Office-${ISO_BUILD_DATE}.iso"
mv ../out-iso2/ArchLinux-Kiosk*.iso "./build/ArchLinux-Kiosk-Studio-A-${ISO_BUILD_DATE}.iso"
rmdir ../out-iso*

echo "✅ Done! Both ISOs are built."