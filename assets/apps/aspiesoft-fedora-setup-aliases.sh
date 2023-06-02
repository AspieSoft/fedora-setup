#!/bin/bash

function update() {
  sudo dnf -y update
  sudo bash /etc/aspiesoft-fedora-setup-updates/update.sh
  sudo dnf clean all
}

function avscan() {
  local scanDir="$1"
  if [ "$scanDir" = "" ]; then
    scanDir="$HOME"
  fi
  sudo nice -n 15 clamscan && sudo clamscan -r --bell --move="/VirusScan/quarantine" --exclude-dir="/VirusScan/quarantine" --exclude-dir="/home/$USER/.clamtk/viruses" --exclude-dir="smb4k" --exclude-dir="/run/user/$USER/gvfs" --exclude-dir="/home/$USER/.gvfs" --exclude-dir=".thunderbird" --exclude-dir=".mozilla-thunderbird" --exclude-dir=".evolution" --exclude-dir="Mail" --exclude-dir="kmail" --exclude-dir="^/sys" "$scanDir"
  unset scanDir
}
