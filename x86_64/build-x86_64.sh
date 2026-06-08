#!/bin/bash
set -e

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

# Replace line
echo "🔧 Patching packages.x86_64..."
cat <<EOF >> $CONFIG_DIR/packages.x86_64
# Our caged Application
$CAGED_APP
EOF

echo "🔧 Patching Cage Service..."
sed -i "s|^ExecStart=.*|$CAGEEXECSTART_LINE|" "$CAGE_SERVICE_PATH"
sed -i "s/^User=<user>/User=$USERNAME/" "$CAGE_SERVICE_PATH"

echo "🔧 Patching TTY3 for autologin..."
sed -i "s/--autologin <user>/--autologin $USERNAME/" "$GETTY_TTY3_SERVICE"

echo "🔧 Setting up user $USERNAME..."
if grep -q "^<user>:" "$SHADOW_FILE"; then
    sed -i "s|^<user>:[^:]*:|$USERNAME:$USERPASSWORDHASH:|" "$SHADOW_FILE" &&
    echo "✅ Updated $SHADOW_FILE" || echo "❌ Failed to update $SHADOW_FILE"
else
    echo "⚠️ Pattern not found in $SHADOW_FILE"
fi

if grep -q "<user>" "$GROUP_FILE"; then
    sed -i "s/<user>/$USERNAME/g" "$GROUP_FILE" &&
    echo "✅ Updated $GROUP_FILE" || echo "❌ Failed to update $GROUP_FILE"
else
    echo "⚠️ Pattern not found in $GROUP_FILE"
fi

if grep -q "^<user>:" "$GSHADOW_FILE"; then
    sed -i "s/^<user>:.*$/$USERNAME:!*::/g" "$GSHADOW_FILE" &&
    echo "✅ Updated $GSHADOW_FILE" || echo "❌ Failed to update $GSHADOW_FILE"
else
    echo "⚠️ Pattern not found in $GSHADOW_FILE"
fi

if grep -q "<user>" "$PASSWD_FILE"; then
    sed -i "s/<user>/$USERNAME/g" "$PASSWD_FILE" &&
    echo "✅ Updated $PASSWD_FILE" || echo "❌ Failed to update $PASSWD_FILE"
else
    echo "⚠️ Pattern not found in $PASSWD_FILE"
fi

echo "▶️ Downloading latest ArchLinux Docker Image..."
if ! docker pull archlinux:latest; then
  echo "❌ Failed to pull ArchLinux Docker image."
  exit 1
fi

mkdir -p "$CACHE_DIR/pacman"

# Build ISO in Docker
echo "▶️ Building ISO..."
if ! docker run -it --privileged \
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