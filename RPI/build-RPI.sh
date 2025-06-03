#!/bin/bash
set -e

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

export RPIGEN="$CONFIG_DIR/pi-gen"
export RPIGEN_CONFIG="$RPIGEN/config"

# Replace line
echo "🔧 Patching Cage Service..."
sed -i "s|^ExecStart=.*|$CAGEEXECSTART_LINE|" "$CAGE_SERVICE_PATH"
sed -i "s/^User=<user>/User=$USERNAME/" "$CAGE_SERVICE_PATH"

echo "🔧 Patching TTY3 for autologin..."
sed -i "s/--autologin <user>/--autologin $USERNAME/" "$GETTY_TTY3_SERVICE"

echo "🔧 Patching Stages..."
patch -d "$RPIGEN" -p1 < "$CONFIG_DIR/files/01-sys-tweaks-packages-patch.patch"
rm "$RPIGEN/stage2/01-sys-tweaks/00-patches/02-swap.diff"

echo "🔧 Creating our own step..."
mkdir -p "$RPIGEN/stage2/99-kiosk-config"

cat <<EOF > $RPIGEN/stage2/99-kiosk-config/01-run.sh
#!/bin/bash -e
# Copy the contents of /pi-gen/airootfs into it
cp -a /pi-gen/airootfs/. "\${ROOTFS_DIR}/"
chmod 755 -R "\${ROOTFS_DIR}/opt/scripts"

on_chroot <<END
  systemctl enable overlay-root.service
END

EOF

chmod +x "$RPIGEN/stage2/99-kiosk-config/01-run.sh"

cat <<EOF > $RPIGEN/stage2/99-kiosk-config/00-packages
cage
dialog
wlr-randr
xwayland
alsa-utils
pipewire
wireplumber
pipewire-alsa
pipewire-pulse
pipewire-jack
pipewire-audio
pipewire-v4l2
firefox
EOF

echo "🔧 Setting up config..."
cat <<EOF > $RPIGEN_CONFIG
IMG_NAME='$RPI_IMG_NAME'
PI_GEN_RELEASE='$RPI_PI_GEN_RELEASE'
DEPLOY_COMPRESSION='$RPI_DEPLOY_COMPRESSION'
COMPRESSION_LEVEL='$RPI_COMPRESSION_LEVEL'
USE_QEMU='$RPI_USE_QEMU'
LOCALE_DEFAULT='$RPI_LOCALE_DEFAULT'
TARGET_HOSTNAME='$RPI_TARGET_HOSTNAME'
KEYBOARD_KEYMAP='$RPI_KEYBOARD_KEYMAP'
KEYBOARD_LAYOUT='$RPI_KEYBOARD_LAYOUT'
TIMEZONE_DEFAULT='$RPI_TIMEZONE_DEFAULT'
FIRST_USER_NAME=$USERNAME
FIRST_USER_PASS=$USERPASSWORD
DISABLE_FIRST_BOOT_USER_RENAME='$RPI_DISABLE_FIRST_BOOT_USER_RENAME'
WPA_COUNTRY='$RPI_WPA_COUNTRY'
ENABLE_SSH='$RPI_ENABLE_SSH'
EOF

touch "$RPIGEN/stage3/SKIP" "$RPIGEN/stage4/SKIP" "$RPIGEN/stage5/SKIP"
touch "$RPIGEN/stage4/SKIP_IMAGES" "$RPIGEN/stage5/SKIP_IMAGES"

echo "🔧 Removing .git in $RPIGEN..."
rm "$RPIGEN/.git"

echo "🔧 Patching build scripts..."
export GIT_HASH=${GIT_HASH:-"$(git rev-parse HEAD)"}
sed -i "s|export GIT_HASH=${GIT_HASH:-\"$(git rev-parse HEAD)\"}|export GIT_HASH=${GIT_HASH:-\"$GIT_HASH\"}|" "$RPIGEN/build.sh"
sed -i "s|export GIT_HASH=${GIT_HASH:-\"$(git rev-parse HEAD)\"}|export GIT_HASH=${GIT_HASH:-\"$GIT_HASH\"}|" "$RPIGEN/build-docker.sh"

echo "🔧 Merging airootfs..."
mv "$CONFIG_DIR/airootfs" "$CONFIG_DIR/pi-gen/airootfs"

echo "🔧 Making system ReadOnly..."
install -m 755 "$CONFIG_DIR/files/overlay-root.sh" "${ROOTFS_DIR}/usr/local/sbin/"
install -m 644 "$CONFIG_DIR/files/overlay-root.service" "${ROOTFS_DIR}/etc/systemd/system/"

echo "▶️ Building Image..."
cd "$CONFIG_DIR/pi-gen"
./build-docker.sh

echo "▶️ Moving Built Image..."
find "$CONFIG_DIR/pi-gen/deploy" -maxdepth 1 -name "*.img.xz" -exec mv {} "$ISO_DIR/" \;
