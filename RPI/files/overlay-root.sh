#!/bin/bash

# Early init script to remount root fs as overlay
# This script runs via systemd before local-fs.target

set -e

# If our flag doesnt exist set it and reboot
if [ ! -f "/readonly-done" ]; then
    touch /readonly-done
    /usr/bin/raspi-config nonint do_overlayfs 0
    reboot
    exit 0
fi