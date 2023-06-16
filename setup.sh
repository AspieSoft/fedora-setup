#!/bin/bash

cd $(dirname "$0")
dir="$PWD"


autoUpdates="y"
slowWifi="n"

processStep="0"

if [ -f "ProcessStep.txt" ]; then
  processStep="$(cat ProcessStep.txt)"
fi

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

  read -n1 -p "Would you like automatic updates to be pulled from the github repo (Y/n)? " autoUpdates ; echo >&2
  read -n1 -p "Are you downloading on slow internet or a hotspot (y/N)? " slowWifi ; echo >&2
fi

echo "Starting Install..."
echo

function cleanup() {
  # reset login timeout
  sudo sed -r -i 's/^Defaults([\t ]+)(.*)env_reset(.*), (timestamp_timeout=1801,?\s*)+$/Defaults\1\2env_reset\3/m' /etc/sudoers &>/dev/null

  # enable sleep
  sudo systemctl --runtime unmask sleep.target suspend.target hibernate.target hybrid-sleep.target &>/dev/null
  gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'suspend' &>/dev/null

  # enable auto updates
  gsettings set org.gnome.software download-updates true

  # enable auto suspend
  sudo perl -0777 -i -pe 's/#AspieSoft-TEMP-START(.*)#AspieSoft-TEMP-END//s' /etc/systemd/logind.conf &>/dev/null

  # reenable dnf timeout if temporarly disabled
  sudo perl -0777 -i -pe 's/#AspieSoft-TEMP-START(.*)#AspieSoft-TEMP-END//s' /etc/dnf/dnf.conf &>/dev/null

  cd "$dir"
  echo "$processStep" | sudo tee "ProcessStep.txt"
}
trap cleanup EXIT

function cleanupexit() {
  cleanup
  exit
}
trap cleanupexit SIGINT


# To log into sudo with password prompt
sudo echo


# extend login timeout
sudo sed -r -i 's/^Defaults([\t ]+)(.*)env_reset(.*)$/Defaults\1\2env_reset\3, timestamp_timeout=1801/m' /etc/sudoers &>/dev/null

# disable sleep
sudo systemctl --runtime mask sleep.target suspend.target hibernate.target hybrid-sleep.target &>/dev/null
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' &>/dev/null

# disable auto updates
gsettings set org.gnome.software download-updates false

# disable auto suspend
echo "#AspieSoft-TEMP-START" | sudo tee -a /etc/systemd/logind.conf &>/dev/null
echo "HandleLidSwitch=ignore" | sudo tee -a /etc/systemd/logind.conf &>/dev/null
echo "HandleLidSwitchDocked=ignore" | sudo tee -a /etc/systemd/logind.conf &>/dev/null
echo "IdleAction=ignore" | sudo tee -a /etc/systemd/logind.conf &>/dev/null
echo "#AspieSoft-TEMP-END" | sudo tee -a /etc/systemd/logind.conf &>/dev/null


function waitForWifi() {
  wget -q --spider http://google.com
  if ! [ $? -eq 0 ]; then
    echo
    echo "Internet Connection Error: Waiting for wifi..."
    echo

    sleep 10

    wget -q --spider http://google.com

    while ! [ $? -eq 0 ]; do
      sleep 3
      wget -q --spider http://google.com
    done
  fi

  command "$@"

  wget -q --spider http://google.com
  if ! [ $? -eq 0 ]; then
    echo "Internet Connection Error: Trying Again..."
    sleep 10
    waitForWifi "$@"
  fi
}


for file in bin/scripts/*.sh; do
  gitSum=$(waitForWifi curl --silent "https://raw.githubusercontent.com/AspieSoft/fedora-setup/master/$file" | sha256sum | sed -E 's/([a-zA-Z0-9]+).*$/\1/')
  sum=$(sha256sum "$file" | sed -E 's/([a-zA-Z0-9]+).*$/\1/')
  if ! [ "$sum" = "$gitSum" ]; then
    echo "error: checksum failed!"
    exit
  fi
done


# set theme basics
gsettings set org.gnome.desktop.interface clock-format 12h
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"


# improve dnf speed
if ! grep -R "^# Added for Speed" "/etc/dnf/dnf.conf"; then
  echo "# Added for Speed" | sudo tee -a /etc/dnf/dnf.conf
  echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf
  echo "max_parallel_downloads=5" | sudo tee -a /etc/dnf/dnf.conf
  echo "defaultyes=True" | sudo tee -a /etc/dnf/dnf.conf
  echo "keepcache=True" | sudo tee -a /etc/dnf/dnf.conf
fi

if [ "$slowWifi" = "y" -o "$slowWifi" = "Y" ] ; then
  # temporarly reduce dnf timeout
  if ! grep -R "^#AspieSoft-TEMP-START" "/etc/dnf/dnf.conf"; then
    echo "#AspieSoft-TEMP-START" | sudo tee -a /etc/dnf/dnf.conf &>/dev/null
    echo "minrate=300" | sudo tee -a /etc/dnf/dnf.conf &>/dev/null
    echo "timeout=60" | sudo tee -a /etc/dnf/dnf.conf &>/dev/null
    echo "#AspieSoft-TEMP-END" | sudo tee -a /etc/dnf/dnf.conf &>/dev/null
  fi
else
  # reenable dnf timeout if temporarly disabled
  sudo perl -0777 -i -pe 's/#AspieSoft-TEMP-START(.*)#AspieSoft-TEMP-END//s' /etc/dnf/dnf.conf &>/dev/null
fi

if [ "$processStep" -lt "1" ]; then
  echo "updating..."
  waitForWifi sudo dnf -y update

  processStep=$((processStep+1))
fi

# install ufw and disable firewalld
if [ "$processStep" -lt "2" ]; then
  echo "installing ufw..."
  waitForWifi sudo dnf -y install ufw
  sudo systemctl stop firewalld
  sudo systemctl disable firewalld
  sudo systemctl enable ufw
  sudo systemctl start ufw
  sudo ufw enable
  sudo ufw delete allow SSH
  sudo ufw delete allow to 244.0.0.251 app mDNS
  sudo ufw delete allow to ff02::fb app mDNS

  processStep=$((processStep+1))
fi

if [ "$processStep" -lt "3" ]; then
  waitForWifi sudo dnf -y makecache

  processStep=$((processStep+1))
fi

# RUN programing-languages.sh
if [ "$processStep" -lt "4" ]; then
  echo "installing programing languages..."
  bash "./bin/scripts/programing-languages.sh"

  processStep=$((processStep+1))
fi

# update grub timeout
if [ "$processStep" -lt "5" ]; then
  echo "changing grub timeout..."
  sudo cp -n /etc/default/grub /etc/default/grub-backup
  sudo sed -r -i 's/^GRUB_TIMEOUT_STYLE=(.*)$/GRUB_TIMEOUT_STYLE=menu/m' /etc/default/grub
  sudo sed -r -i 's/^GRUB_TIMEOUT=(.*)$/GRUB_TIMEOUT=0/m' /etc/default/grub
  sudo update-grub

  processStep=$((processStep+1))
fi

# RUN preformance.sh
if [ "$processStep" -lt "6" ]; then
  echo "installing preformance upgrades..."
  bash "./bin/scripts/preformance.sh"

  processStep=$((processStep+1))
fi

# RUN fix.sh
if [ "$processStep" -lt "7" ]; then
  echo "installing common fices..."
  bash "./bin/scripts/fix.sh"

  processStep=$((processStep+1))
fi

# RUN security.sh
if [ "$processStep" -lt "8" ]; then
  echo "installing security apps..."
  bash "./bin/scripts/security.sh"

  processStep=$((processStep+1))
fi

# RUN repos.sh
if [ "$processStep" -lt "9" ]; then
  echo "installing repos..."
  bash "./bin/scripts/repos.sh"

  processStep=$((processStep+1))
fi

# RUN apps.sh
if [ "$processStep" -lt "10" ]; then
  echo "installing apps..."
  bash "./bin/scripts/apps.sh"

  processStep=$((processStep+1))
fi

# RUN shortcuts.sh
if [ "$processStep" -lt "11" ]; then
  echo "installing shortcuts..."
  bash "./bin/scripts/shortcuts.sh"

  processStep=$((processStep+1))
fi

if [ "$processStep" -lt "12" ]; then
  waitForWifi sudo dnf -y update
  echo "running dnf clean..."
  sudo dnf clean all

  processStep=$((processStep+1))
fi

# RUN theme.sh
if [ "$processStep" -lt "13" ]; then
  echo "installing theme..."
  bash "./bin/scripts/theme.sh"

  processStep=$((processStep+1))
fi


# setup aspiesoft auto updates
if [ "$autoUpdates" = "y" -o "$autoUpdates" = "Y" -o "$autoUpdates" = "" -o "$autoUpdates" = " " ] ; then
  if [ "$processStep" -lt "14" ]; then
    echo "installing auto updates..."

    sudo mkdir -p /etc/aspiesoft-fedora-setup-updates
    sudo cp -rf ./assets/apps/aspiesoft-fedora-setup-updates/* /etc/aspiesoft-fedora-setup-updates
    sudo rm -f /etc/aspiesoft-fedora-setup-updates/aspiesoft-fedora-setup-updates.service
    sudo cp -f ./assets/apps/aspiesoft-fedora-setup-updates/aspiesoft-fedora-setup-updates.service "/etc/systemd/system"
    gitVer="$(waitForWifi curl --silent 'https://api.github.com/repos/AspieSoft/fedora-setup/releases/latest' | grep '\"tag_name\":' | sed -E 's/.*\"([^\"]+)\".*/\1/')"
    echo "$gitVer" | sudo tee "/etc/aspiesoft-fedora-setup-updates/version.txt"

    sudo systemctl daemon-reload
    sudo systemctl enable aspiesoft-fedora-setup-updates.service
    sudo systemctl start aspiesoft-fedora-setup-updates.service

    processStep=$((processStep+1))
  fi
fi


cleanup


# clean up and restart gnome
if [[ "$PWD" =~ fedora-setup/?$ ]]; then
  rm -rf "$PWD"
fi

echo "Install Finished!"

echo
echo "Ready To Restart Gnome!"
echo
read -n1 -p "Press any key to continue..." input ; echo >&2

# note: this will logout the user
killall -3 gnome-shell
