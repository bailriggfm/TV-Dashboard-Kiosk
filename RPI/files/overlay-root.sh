#!/bin/bash

# Early init script to remount root fs as overlay
# This script runs via systemd before local-fs.target

set -e

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
