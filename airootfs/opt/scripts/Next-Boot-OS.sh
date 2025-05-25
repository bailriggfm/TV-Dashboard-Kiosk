#!/bin/bash

# Ensure the script is running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root."
    exit 1
fi

# Check if the system is in UEFI mode
if [ ! -d /sys/firmware/efi ]; then
    dialog --title "Error" --msgbox "This system is not booted in UEFI mode.\nPlease reboot in UEFI mode to use this script." 10 50
    clear
    exit 1
fi

# Gather UEFI boot options
BOOT_OPTIONS=$(efibootmgr | grep -E "Boot[0-9A-F]{4}" | awk -F' ' '{print $1 " " substr($0, index($0,$3))}' | sed 's/\*//g')

# Check if there are any options
if [ -z "$BOOT_OPTIONS" ]; then
    dialog --title "UEFI Boot Options" --msgbox "No UEFI boot options found." 8 40
    clear
    exit 1
fi

# Look for Windows boot entries
WINDOWS_ENTRY=""
while IFS= read -r line; do
    if echo "$line" | grep -i "windows\|microsoft" > /dev/null; then
        WINDOWS_ENTRY="$line"
        break
    fi
done <<< "$BOOT_OPTIONS"

# If Windows entry found, ask for confirmation to boot into it
if [ -n "$WINDOWS_ENTRY" ]; then
    WINDOWS_ID=$(echo "$WINDOWS_ENTRY" | awk '{print $1}')
    WINDOWS_NAME=$(echo "$WINDOWS_ENTRY" | cut -d' ' -f2-)

    # Limit WINDOWS_NAME to 50 characters
    if [ ${#WINDOWS_NAME} -gt 50 ]; then
        WINDOWS_NAME="${WINDOWS_NAME:0:47}..."
    fi

    dialog --title "Windows Boot Option Found" \
           --yesno "Windows boot option found:\n\n$WINDOWS_NAME\n\nDo you want to reboot into Windows?" 10 60

    if [ $? -eq 0 ]; then
        # User confirmed, boot into Windows
        BOOT_NUM=${WINDOWS_ID:4}
        clear
        efibootmgr -n "$BOOT_NUM" && reboot
        exit 0
    fi
    # If user declined, continue with default behavior
fi

# Prepare menu entries
MENU_ENTRIES=()
while IFS= read -r line; do
    ID=$(echo "$line" | awk '{print $1}')
    NAME=$(echo "$line" | cut -d' ' -f2-)
    MENU_ENTRIES+=("$ID" "$NAME")
done <<< "$BOOT_OPTIONS"

# Display menu
CHOICE=$(dialog --clear --title "Select UEFI Boot Option" \
                --menu "Choose a UEFI boot option to reboot into:" 20 80 10 \
                "${MENU_ENTRIES[@]}" 2>&1 >/dev/tty)

# Check if the user canceled
if [ $? -ne 0 ]; then
    clear
    exit 0
fi

clear

# Extract the numeric part of the boot option (e.g. Boot0001 -> 0001)
BOOT_NUM=${CHOICE:4}

# Reboot into the selected option
efibootmgr -n "$BOOT_NUM" && reboot
exit 0