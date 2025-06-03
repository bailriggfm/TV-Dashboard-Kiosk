#!/bin/bash

# Early init script to remount root fs as overlay
# This script runs via systemd before local-fs.target

set -e

if ! FWLOC=$(/usr/lib/raspberrypi-sys-mods/get_fw_loc); then
  whiptail --msgbox "Could not determine firmware partition" 20 60
  poweroff -f
fi

CMDLINE="$FWLOC/cmdline.txt"

# Check if cmdline.txt exists
if [ ! -f "$CMDLINE" ]; then
    echo "Error: $CMDLINE not found."
    exit 1
fi

# Check for the init override
if grep -q 'init=/usr/lib/raspberrypi-sys-mods/firstboot' "$CMDLINE"; then
    echo "Found init=/usr/lib/raspberrypi-sys-mods/firstboot in cmdline.txt. Exiting."
    exit 0
fi

# Check if 'ro' is already present
if ! grep -qw '\bro\b' "$CMDLINE"; then
    echo "'ro' not found in cmdline.txt. Adding it now..."
    sed -i -E 's/\<(root=[^ ]+)\>([ ]+)?(rw)?/\1 ro/' "$CMDLINE"

    echo "Updated cmdline.txt:"
    cat "$CMDLINE"

    echo "Rebooting to apply changes..."
    sync
    reboot
    exit 0
else
    echo "'ro' is already set in cmdline.txt. No changes needed."
fi

# Skip overlay if already running in overlay
if mountpoint -q /ro; then
    echo "Already using overlay. Skipping setup."
    exit 0
fi

# Mount boot and root readonly
mkdir -p /ro
mount -o ro /dev/root /ro

mkdir -p /overlay
mount -t tmpfs tmpfs /overlay

mkdir -p /overlay/upper
mkdir -p /overlay/work

# Mount overlay to a new root
mkdir -p /mnt/overlay-root
mount -t overlay overlay -o lowerdir=/ro,upperdir=/overlay/upper,workdir=/overlay/work /mnt/overlay-root

# Move necessary mount points
for dir in dev proc sys run; do
    mkdir -p /mnt/overlay-root/$dir
    mount --move /$dir /mnt/overlay-root/$dir
done

# Switch to new root
exec switch_root /mnt/overlay-root /sbin/init
