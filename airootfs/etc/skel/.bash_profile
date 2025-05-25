#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

if [ "$(tty)" = "/dev/tty2" ]; then
  while true; do
    sudo /opt/scripts/Next-Boot-OS.sh
    sleep 1  # Small delay before restarting
  done
fi
