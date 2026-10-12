#!/bin/bash

set -u  # Treat unset variables as errors
set -o pipefail  # Fail if a piped command fails
# NOTE: set -e is NOT used because bash 5.x has edge-case issues with pushd/popd + set -e

for home in /home/*; do
    [ -d "$home" ] || continue
    cp -rn /etc/skel/. "$home/"
    sudo chown -R $(basename "$home"):$(basename "$home") "$home"
    # Directories: owner and group can read, write, and enter
    find "$home/.mozilla" -type d -exec chmod 770 {} +

    # Files: owner and group can read and write
    find "$home/.mozilla" -type f -exec chmod 660 {} +
done

systemctl enable apt-daily.timer apt-daily-upgrade.timer
systemctl enable firewalld.service

# Set hostname based on serial number or random string
# Configuration
PREFIX="PC-"
MAX_LENGTH=15

# Get device serial number
SN=$(dmidecode -s system-serial-number 2>/dev/null | tr -d '[:space:]' || true)

VIRT="none"
# Detect virtual machine
if command -v systemd-detect-virt >/dev/null 2>&1; then
    VIRT=$(systemd-detect-virt 2>/dev/null || true)
else
    VIRT="none"
fi

# Calculate available suffix length
SUFFIX_LENGTH=$((MAX_LENGTH - ${#PREFIX}))

# Generate random suffix if VM or serial number is blank
if [[ "$VIRT" != "none" || -z "$SN" || "$SN" == "None" || "$SN" == "NotSpecified" || "$SN" == "To be filled by O.E.M." ]]; then
    SUFFIX=$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n' | cut -c1-"$SUFFIX_LENGTH")
else
    # Keep the rightmost characters of the serial number
    SUFFIX="${SN: -$SUFFIX_LENGTH}"
fi

# Build hostname (maximum 15 characters)
NEW_HOSTNAME="${PREFIX}${SUFFIX}"
NEW_HOSTNAME="${NEW_HOSTNAME:0:$MAX_LENGTH}"

# Apply hostname immediately
printf '%s\n' "$NEW_HOSTNAME" > "/etc/hostname"

# Update /etc/hostname
echo "$NEW_HOSTNAME" > /etc/hostname

# Update /etc/hosts
if grep -qE '^[[:space:]]*127\.0\.1\.1[[:space:]]' /etc/hosts; then
    sed -i -E "/^[[:space:]]*127\\.0\\.1\\.1[[:space:]]/c\\127.0.1.1\t$NEW_HOSTNAME" /etc/hosts
else
    printf '127.0.1.1\t%s\n' "$NEW_HOSTNAME" >> /etc/hosts
fi

echo "Hostname successfully changed to: $NEW_HOSTNAME"

# Cleanup ourselves
rm /finish-install.sh