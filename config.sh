#!/bin/bash

# Shared config

# Username & Password for the live user
export USERNAME="live"
export USERPASSWORD="liveuser"

# Cage service configuration
# Please note that some characters may need to be escaped to work with sed.
# Such as &. If you want an & you must put \&
export CAGEEXECSTART_LINE='ExecStart=/usr/bin/cage -s -- /usr/bin/firefox --kiosk --no-remote --start-fullscreen --no-proxy-server "https://google.com"'

# x86_64 CONFIG

# RPI CONFIG
export RPIGEN="$BASE_DIR/RPI/pi-gen"
export RPIGEN_CONFIG="$RPIGEN/config"

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