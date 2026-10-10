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

# Cleanup ourselves
rm /finish-install.sh