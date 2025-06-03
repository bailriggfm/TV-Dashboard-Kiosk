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

# If our flag doesnt exist set it and reboot
if [ ! -f "/readonly-done" ]; then
    touch /readonly-done
    /usr/bin/raspi-config nonint do_overlayfs 0
    reboot
    exit 0
fi