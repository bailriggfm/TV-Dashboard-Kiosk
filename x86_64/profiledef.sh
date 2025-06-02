#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="SimpleLinuxKiosk"
iso_label="LINUX_KIOSK_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%y%m)"
iso_publisher="Ava Glass"
iso_application="Simple Linux Kiosk"
iso_version="$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y.%m.%d)"
install_dir="arch"
buildmodes=('iso')
#bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito'
#           'uefi-ia32.grub.esp' 'uefi-x64.grub.esp'
#           'uefi-ia32.grub.eltorito' 'uefi-x64.grub.eltorito')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito'
           'uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'xz' '-Xbcj' 'x86' '-b' '1M' '-Xdict-size' '1M')
file_permissions=(
  ["/etc/shadow"]="0:0:0400"
  ["/etc/gshadow"]="0:0:0400"
  ["/etc/sudoers.d"]="0:0:0750"
  ["/opt/scripts/Next-Boot-OS.sh"]="0:0:0755"
  ["/opt/scripts/set-volume.sh"]="0:0:0755"
)