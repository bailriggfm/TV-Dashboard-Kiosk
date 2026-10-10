#!/bin/bash
set -e

# Check if the script is running as root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be run as root" >&2
  exit 1
fi

echo "🔧 Patching Build Environment..."
patch -d "$CONFIG_DIR/debian-preseed-iso-generator" -p1 < "$CONFIG_DIR/update-build-script.patch"

echo "🔧 Patching Cage Service..."
sed -i "s|^ExecStart=.*|$CAGEEXECSTART_LINE|" "$CAGE_SERVICE_PATH"
sed -i "s/^User=<user>/User=$USERNAME/" "$CAGE_SERVICE_PATH"
sed -i "s/--autologin <user>/--autologin $USERNAME/" "$GETTY_TTY2_SERVICE"

echo "🔧 Patching TTY4 for autologin..."
sed -i "s/--autologin <user>/--autologin $USERNAME/" "$GETTY_TTY4_SERVICE"

mv "$CONFIG_DIR/airootfs" "$CONFIG_DIR/debian-preseed-iso-generator/files"

rm -r "$CONFIG_DIR/debian-preseed-iso-generator/preseeds"
mv "$CONFIG_DIR/preseeds" "$CONFIG_DIR/debian-preseed-iso-generator/preseeds"

echo "▶️ Downloading latest Debian Trixie Docker Image..."
if ! docker pull debian:trixie; then
  echo "❌ Failed to pull Debian Trixie Docker image."
  exit 1
fi

# Build ISO in Docker
echo "▶️ Building ISO..."
DOCKER_RUN_ARGS=(--privileged)
if [ "${CI:-false}" != "false" ]; then
    DOCKER_RUN_ARGS+=(-it)
fi

export ISO_NAME_PRE="SimpleLinuxKiosk-Debian-Installer-$(openssl rand -base64 4 | tr -dc 'a-zA-Z0-9' | head -c 5)"

if ! docker run "${DOCKER_RUN_ARGS[@]}" \
                --rm \
                -e ISO_NAME_PRE="$ISO_NAME_PRE" \
                -e NO_COLOR=1 \
                -e GREEN=$'\033[0;32m' \
                -e ORANGE=$'\033[0;33m' \
                -e RED=$'\033[0;31m' \
                -e NC=$'\033[0m' \
                -v "$BUILD_TMP":/build \
                -v "$ISO_DIR":/iso \
                -v "$CACHE_DIR/debian":/debian \
                -w /build/config debian:trixie \
                /bin/bash -c '
                cp /debian/*.iso ./debian-preseed-iso-generator/
                apt-get update && apt-get install -y wget curl xorriso cpio gzip gnupg isolinux gnupg debian-archive-keyring
                cp ./grub.cfg ./debian-preseed-iso-generator/
                cp ./menu.cfg ./debian-preseed-iso-generator/
                ./debian-preseed-iso-generator/debian-preseed-iso-generator.sh \
                  --output /iso_tmp \
                  -a amd64
                mv /iso_tmp/default-preseed-debian-amd64-netinst.iso /iso/${ISO_NAME_PRE}.iso
                mv -n ./debian-preseed-iso-generator/*.iso /debian/
            '; then

  echo "❌ Debian installer generation failed."
  exit 1
fi

exit 1