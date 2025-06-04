#!/bin/bash

# Early init script to disable the touchscreen

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
if grep -q 'disable_touchscreen=1' "$CMDLINE"; then
    echo "Found disable_touchscreen=1 in cmdline.txt. Exiting."
    exit 0
fi

# Check if the system is in read-only mode
if [ ! -f "/readonly-done" ]; then
  # If our flag doesnt exist set it and reboot
  echo "Adding disable_touchscreen=1 to cmdline.txt"
  sed -i "s/$/ disable_touchscreen=1/" "$CMDLINE"
  echo "Rebooting system..."
  reboot
  exit 0
fi

exit 1