# Arch Kiosk

A set of minimal scripts based off the default archiso scripts to setup a minimal arch environment and then launch a kiosk.
By default this uses firefox but cage (our wayland environment) supports any application.

## Building

To build this image you are required to install archiso, edk2-ovmf, gnupg, grub and openssl.

Then simply clone this repo, update the ISO1_EXEC in build.sh with either the website you would like to load or another application ensuring to always leave `ExecStart=/usr/bin/cage -s --` at the beginning.

Finally call the build.sh script as root.

After building you will need to remove the work directory `../work-iso1`. Before doing so it is best to check using findmnt that there are no folders mounted within. See: https://wiki.archlinux.org/title/Archiso#Removal_of_work_directory

### Important notes

> [!IMPORTANT]
> If you are calling another application then please make sure it is installed in the packages.x86_64.

> [!IMPORTANT]
> IF the script fails please check that there is nothing mounted under the work directory `../work-iso1` using findmnt see: https://wiki.archlinux.org/title/Archiso#Removal_of_work_directory

## Other Features

Pressing CTRL + ALT + 2 (TTY2) will take you to a TUI allowing you reboot the computer into another boot option detected by UEFI firmware at boot. This can be disabled by removing `airootfs/etc/systemd/system/getty@tty2.service.d/autologin.conf` and the respective entry in `airootfs/etc/skel/.bash_profile`.

Pressing CTRL + ALT + 3 (TTY3) will automatically log you into a tty as user live.

The sudo password for the user is liveuser. If you need to keep the system secure please change the password in the build.sh script

By default the localtime is set to Europe/London. This can be updated by updating the symlink for `airootfs/etc/localtime`

Firefox is configured on all users with a custom default firefox profile. This profile enables autoplay of media, disables first-run behaviours, disables all telemetry and sets the theme to a dark theme. This is useful for the kiosk that may not have user interaction but have autoplay of media. For safety we also specify the profile when we start firefox.