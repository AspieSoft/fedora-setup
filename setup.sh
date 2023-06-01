#!/bin/bash

cd $(dirname "$0")

if ! [ "$1" = "-y" ]; then
  echo
  echo "Notice: This script will completely transform your desktop and modify your settings!"
  echo "Creating a backup before running this script is recommended."
  echo "Your gnome session will restart (and log you out) when the install is complete."
  echo
  read -n1 -p "Would you like to continue with the install (Y/n)? " input ; echo >&2

  if ! [ "$input" = "y" -o "$input" = "Y" -o "$input" = "" -o "$input" = " " ] ; then
    echo "install canceled!"
    exit
  fi

  echo "Starting Install..."
  echo
fi

function cleanup() {
  # reset login timeout
  sudo sed -r -i 's/^Defaults([\t ]+)(.*)env_reset(.*), (timestamp_timeout=1801,?\s*)+$/Defaults\1\2env_reset\3/m' /etc/sudoers &>/dev/null

  # enable sleep
  sudo systemctl --runtime unmask sleep.target suspend.target hibernate.target hybrid-sleep.target &>/dev/null

  # enable auto updates
  gsettings set org.gnome.software download-updates true
}
trap cleanup EXIT


# To log into sudo with password prompt
sudo echo


# extend login timeout
sudo sed -r -i 's/^Defaults([\t ]+)(.*)env_reset(.*)$/Defaults\1\2env_reset\3, timestamp_timeout=1801/m' /etc/sudoers &>/dev/null

# disable sleep
sudo systemctl --runtime mask sleep.target suspend.target hibernate.target hybrid-sleep.target &>/dev/null

# disable auto updates
gsettings set org.gnome.software download-updates false


# set theme basics
gsettings set org.gnome.desktop.interface clock-format 12h
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"


# improve dnf speed
echo "#Added for Speed" | sudo tee -a /etc/dnf/dnf.conf
echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf
echo "max_parallel_downloads=5" | sudo tee -a /etc/dnf/dnf.conf
echo "defaultyes=True" | sudo tee -a /etc/dnf/dnf.conf
echo "keepcache=True" | sudo tee -a /etc/dnf/dnf.conf

sudo dnf -y update

# install ufw and disable firewalld
sudo dnf -y install ufw
sudo systemctl stop firewalld
sudo systemctl disable firewalld
sudo systemctl enable ufw
sudo systemctl start ufw
sudo ufw enable
sudo ufw delete allow SSH
sudo ufw delete allow to 244.0.0.251 app mDNS
sudo ufw delete allow to ff02::fb app mDNS

sudo dnf -y makecache

# RUN programing-languages.sh
bash "./bin/scripts/programing-languages.sh"

# update grub timeout
sudo cp -n /etc/default/grub /etc/default/grub-backup
sudo sed -r -i 's/^GRUB_TIMEOUT_STYLE=(.*)$/GRUB_TIMEOUT_STYLE=menu/m' /etc/default/grub
sudo sed -r -i 's/^GRUB_TIMEOUT=(.*)$/GRUB_TIMEOUT=0/m' /etc/default/grub
sudo update-grub

# RUN preformance.sh
bash "./bin/scripts/preformance.sh"

# RUN fix.sh
bash "./bin/scripts/fix.sh"

# RUN security.sh
bash "./bin/scripts/security.sh"

# RUN repos.sh
bash "./bin/scripts/repos.sh"

# RUN apps.sh
bash "./bin/scripts/apps.sh"

sudo dnf -y update
sudo dnf clean all

# RUN theme.sh
bash "./bin/scripts/theme.sh"


# setup aspiesoft auto updates
sudo mkdir -p /etc/aspiesoft-fedora-setup-updates
sudo cp -rf ./assets/apps/aspiesoft-fedora-setup-updates/* /etc/aspiesoft-fedora-setup-updates
sudo rm -f /etc/aspiesoft-fedora-setup-updates/aspiesoft-fedora-setup-updates.desktop
sudo cp -f ./assets/apps/aspiesoft-fedora-setup-updates/aspiesoft-fedora-setup-updates.desktop "$HOME/.config/autostart"
sudo cp -f ./assets/apps/aspiesoft-fedora-setup-updates/aspiesoft-fedora-setup-updates.desktop "/etc/skel/.config/autostart"
gitVer="$(curl --silent 'https://api.github.com/repos/AspieSoft/fedora-setup/releases/latest' | grep '\"tag_name\":' | sed -E 's/.*\"([^\"]+)\".*/\1/')"
echo "$gitVer" | sudo tee "/etc/aspiesoft-fedora-setup-updates/version.txt"

# reset login timeout
sudo sed -r -i 's/^Defaults([\t ]+)(.*)env_reset(.*), (timestamp_timeout=1801,?\s*)+$/Defaults\1\2env_reset\3/m' /etc/sudoers &>/dev/null

# enable sleep
sudo systemctl --runtime unmask sleep.target suspend.target hibernate.target hybrid-sleep.target &>/dev/null

# enable auto updates
gsettings set org.gnome.software download-updates true

# clean up and restart gnome
if [[ "$PWD" =~ fedora-setup/?$ ]]; then
  rm -rf "$PWD"
fi

echo "Install Finished!"

# note: this will logout the user
killall -3 gnome-shell
