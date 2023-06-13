#!/bin/bash

# install aspiesoft clamav download scanner
if ! [ -d "/etc/aspiesoft-clamav-scanner" ]; then
  sudo mkdir -p /etc/aspiesoft-clamav-scanner
  git clone https://github.com/AspieSoft/linux-clamav-download-scanner.git
  sudo cp -rf linux-clamav-download-scanner/* /etc/aspiesoft-clamav-scanner
  rm linux-clamav-download-scanner
  sudo cp -f ./assets/apps/aspiesoft-clamav-scanner/start.sh /etc/aspiesoft-clamav-scanner
  sudo cp -f ./assets/apps/aspiesoft-clamav-scanner/aspiesoft-clamav-download-scanner.service "/etc/systemd/system"
  sudo systemctl daemon-reload
  sudo systemctl enable aspiesoft-clamav-download-scanner.service
  sudo systemctl start aspiesoft-clamav-download-scanner.service
fi
