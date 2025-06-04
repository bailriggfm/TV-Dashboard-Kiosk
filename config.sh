#!/bin/bash

# Shared config

# Username & Password for the live user
export USERNAME="live"
export USERPASSWORD="liveuser"

# Package to install for the caged application
# i.e. firefox, chromium, etc. - For older Raspberry Pis chromium is recommended. :(
export CAGED_APP="firefox"

# Cage service configuration
# Please note that some characters may need to be escaped to work with sed.
# Such as &. If you want an & you must put \&
#export CAGEEXECSTART_LINE='ExecStart=/usr/bin/cage -s -- /usr/bin/firefox --kiosk --no-remote --start-fullscreen --no-proxy-server "https://screen.bailriggfm.co.uk/view/office?pass=primary"'
export CAGEEXECSTART_LINE='ExecStart=/usr/bin/cage -s -- /usr/bin/firefox --kiosk --no-remote --start-fullscreen --no-proxy-server "https://screen.bailriggfm.co.uk/view/studio-a"'
export CAGEEXECSTART_LINE='ExecStart=/usr/bin/cage -s -- /usr/bin/firefox --kiosk --no-remote --start-fullscreen --no-proxy-server "https://screen.bailriggfm.co.uk/view/player"'

# Option if using chromium instead of firefox
#export CAGEEXECSTART_LINE='ExecStart=/usr/bin/cage -s -- /usr/bin/chromium --kiosk "https://screen.bailriggfm.co.uk/view/office?pass=primary" --noerrdialogs --disable-infobars --incognito --start-fullscreen --autoplay-policy=no-user-gesture-required --disable-session-crashed-bubble --no-proxy-server --no-first-run'
#export CAGEEXECSTART_LINE='ExecStart=/usr/bin/cage -s -- /usr/bin/chromium --kiosk "https://screen.bailriggfm.co.uk/view/studio-a" --noerrdialogs --disable-infobars --incognito --start-fullscreen --autoplay-policy=no-user-gesture-required --disable-session-crashed-bubble --no-proxy-server --no-first-run'
#export CAGEEXECSTART_LINE='ExecStart=/usr/bin/cage -s -- /usr/bin/chromium --kiosk "https://screen.bailriggfm.co.uk/view/player" --noerrdialogs --disable-infobars --incognito --start-fullscreen --autoplay-policy=no-user-gesture-required --disable-session-crashed-bubble --no-proxy-server --no-first-run'

# x86_64 CONFIG

# RPI CONFIG
export RPI_IMG_NAME='SimpleLinuxKiosk-RPI'
export RPI_PI_GEN_RELEASE='Simple Linux Kiosk - Raspberry Pi Version'
export RPI_DEPLOY_COMPRESSION='xz'
export RPI_COMPRESSION_LEVEL='9'
export RPI_USE_QEMU='0'
export RPI_LOCALE_DEFAULT='en_GB.UTF-8'
export RPI_TARGET_HOSTNAME='rpi-kiosk'
export RPI_KEYBOARD_KEYMAP='gb'
export RPI_KEYBOARD_LAYOUT='English (UK)'
export RPI_TIMEZONE_DEFAULT='Europe/London'
export RPI_DISABLE_FIRST_BOOT_USER_RENAME='1'
export RPI_WPA_COUNTRY='GB'
export RPI_ENABLE_SSH='0'

# Do not change these values unless you have updated any other relevant files.

# Essential Directories
export BUILD_DIR="$BASE_DIR/build"
mkdir -p "$BUILD_DIR"
export ISO_DIR="$BUILD_DIR/iso"
mkdir -p "$ISO_DIR"
export BUILD_TMP="$(mktemp -d $BUILD_DIR/build-XXXXXXXXXX)"
export CONFIG_DIR="$BUILD_TMP/config"
mkdir -p "$CONFIG_DIR"
export CACHE_DIR="$BUILD_DIR/cache"
mkdir -p "$CACHE_DIR"

# Config Files - Well the ones that need updating.
export CAGE_SERVICE_PATH="$CONFIG_DIR/airootfs/etc/systemd/system/cage@.service"
export GETTY_TTY3_SERVICE="$CONFIG_DIR/airootfs/etc/systemd/system/getty@tty3.service.d/autologin.conf"

# x86_64 Only
export SHADOW_FILE="$CONFIG_DIR/airootfs/etc/shadow"
export GROUP_FILE="$CONFIG_DIR/airootfs/etc/group"
export GSHADOW_FILE="$CONFIG_DIR/airootfs/etc/gshadow"
export PASSWD_FILE="$CONFIG_DIR/airootfs/etc/passwd"


# Contants
export USERPASSWORDHASH=$(echo "$USERPASSWORD" | openssl passwd -6 -stdin) # Generate a password with a random salt