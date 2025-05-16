#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ "$(tty)" = "/dev/tty2" ]; then
  sudo /etc/Next-Boot-OS.sh
fi
