# Simple Linux Kiosk

A set of minimal scripts based off the default archiso and pi-gen scripts to setup a minimal environment and then launch a kiosk.
By default this uses firefox but cage (our wayland environment) supports any application.

## Building

To build this image you are only required to install docker and git as the builds will be built within docker.
This allows building on non-arch OS.

Then simply clone this repo, update the `CAGEEXECSTART_LINE` in `config.sh` with either the website you would like to load or another application ensuring to always leave `ExecStart=/usr/bin/cage -s --` at the beginning.

Finally call the build.sh script as root.

After building an x86_64 image you will need to remove the work directory `./build/build-XXXXXXXXXX/work`. Before doing so it is best to check using findmnt that there are no folders mounted within. See: https://wiki.archlinux.org/title/Archiso#Removal_of_work_directory

### Important notes

> [!IMPORTANT]
> If you are calling another application then please make sure it is defined in `$CAGED_APP`.
> This variable supports a list of packages if required.

> [!IMPORTANT]
> IF the script x86_64 fails please check that there is nothing mounted under the work directory `./build/build-XXXXXXXXXX/work` using findmnt see: https://wiki.archlinux.org/title/Archiso#Removal_of_work_directory

> [!IMPORTANT]
> Ensure you have checked out any git submodules with `git submodule update --init`

> [!NOTE]
> The x86_64 images only take approx 10-15 minutes to build on a performant system, however RPI images may take up to 30+ minutes.

> [!WARNING]
> While untested there is theoretically no reason these images cannot be built within a WSL system.

## Other Features

On the x86_64 inage pressing CTRL + ALT + 2 (TTY2) will take you to a TUI allowing you reboot the computer into another boot option detected by UEFI firmware at boot. This can be disabled by removing the `override.conf` file in the `x86_64/airootfs/etc/systemd/system/getty@tty2.service.d` folder. On the RPI image this is configured to be raspi-config

Pressing CTRL + ALT + 3 (TTY3) will automatically log you into a tty as your defined user.

The default sudo password for the user is liveuser. If you need to keep the system secure please change the password in the config.sh script

By default the localtime is set to Europe/London. For x86_64 This can be updated by updating the symlink for `airootfs/etc/localtime`

On the RPI build the PIs touchscreen is disabled to hide the mouse cursor when no mouse is connected. If you need the touchscreen feature please remove this service from `RPI/build-RPI.sh`

### Firefox restrictions

Firefox is configured on all users with a custom default firefox profile. This profile enables autoplay of media, disables first-run behaviours, disables all telemetry and sets the theme to a dark theme. This is useful for the kiosk that may not have user interaction but have autoplay of media. For safety we also specify the profile when we start firefox.

This firefox config also sets various settings to create a more secure kiosk environment like disabling passwords, multiple tabs, and various developer tools.

The specifics of this can be edited/viewed in `airootfs-shared/etc/firefox/policies/policies.json` and `airootfs-shared/etc/skel/.mozilla/firefox/m1j0kl8f.kiosk_profile/user.js`. These settings are applied to all users by default.

### Chromium restictions

If the default chromium start line is used chromium is booted with similar (but potentially less restrictive) restrictions to firefox. These can be edited in `airootfs-shared/etc/chromium/policies/managed/kiosk_policies.json`.

By default a symlink exists to the defult Google Chrome config to make Chrome inherit these same settings.

## Read-Only Nature

By default both the x86_64 and the RPI images are configured to be read-only once booted storing any changes made to the filesystem in memory. This is done to significantly reduce the wear and any flash/removable media the images may be loaded onto as well as ensure that should the system crash rebooting will always restore the system to a known good state.

Because of this remote connection features of the images are disabled, you should use a secure user password and you are encouraged to regularly rebuild the images to update them.

On the x86_64 images it is not possible to disable this functionality due to the nature of the way the image is built (using squashfs where the entire os is loaded into memory). For the RPI images this can be disabled by editing the `RPI/files/overlay-root.sh` script.

Because x86_64 images are loaded into memory before booting them this does allow the boot medium to be removed, however the system will not be able to reboot into the image due to a lack of boot media. This does not apply to the RPI images, boot media must remain within the device while the os is booted.

> [!NOTE]
> Theoretically x86_64 images could have persistance enabled on them with the help of overlayfs, similarly to how the RPI is made readonly, where data could be written to a persistance partition outside of the image however this is untested.
