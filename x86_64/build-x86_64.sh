#!/bin/bash
set -e

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Replace line
echo "🔧 Patching Cage Service..."
sed -i "s|^ExecStart=.*|$CAGEEXECSTART_LINE|" "$CAGE_SERVICE_PATH"
sed -i "s/^User=<user>/User=$USERNAME/" "$CAGE_SERVICE_PATH"

echo "🔧 Setting up user $USERNAME..."
sed -i "s|^<user>:[^:]*:|$USERNAME:$USERPASSWORDHASH:|" "$SHADOW_FILE"
sed -i "s/\b<user>\b/$USERNAME/g" "$GROUP_FILE"
sed -i "s/--autologin <user>/--autologin $USERNAME/" "$GETTY_TTY3_SERVICE"
sed -i "s/^<user>:.*$/$USERNAME:!*::/" "$GSHADOW_FILE"
sed -i "s/^<user>:/$USERNAME:/" "$PASSWD_FILE"

echo "▶️ Downloading latest ArchLinux Docker Image..."
if ! docker pull archlinux:latest; then
  echo "❌ Failed to pull ArchLinux Docker image."
  exit 1
fi

mkdir -p "$CACHE_DIR/pacman"

# Build ISO in Docker
echo "▶️ Building ISO..."
if ! docker run --privileged \
                --rm \
                -v "$BUILD_TMP":/build \
                -v "$ISO_DIR":/iso \
                -v "$CACHE_DIR/pacman":/pacman \
                -w /build archlinux:latest \
                /bin/bash -c '
                pacman -Sy --noconfirm archlinux-keyring archiso edk2-ovmf gnupg grub openssl || {
                    echo "❌ Failed to install required packages with pacman.";
                    exit 1;
                }
                mkdir -p /build/iso
                mkarchiso -v -w "/build/work" -o "/iso" "/build/config"
            '; then

  echo "❌ mkarchiso failed."
  exit 1
fi

echo "✅ Done! ISO built."