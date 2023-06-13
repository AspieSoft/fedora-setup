#!/bin/bash

# install aspiesoft clamav download scanner
if ! [ -d "/etc/aspiesoft-clamav-scanner" ]; then
  sudo mkdir -p /etc/aspiesoft-clamav-scanner
  git clone https://github.com/AspieSoft/linux-clamav-download-scanner.git
  sudo -R -f cp linux-clamav-download-scanner/* /etc/aspiesoft-clamav-scanner
  rm linux-clamav-download-scanner
  sudo cp -f ../../assets/apps/aspiesoft-clamav-scanner/start.sh /etc/aspiesoft-clamav-scanner
  sudo cp -f ../../assets/apps/aspiesoft-clamav-scanner/aspiesoft-clamav-scanner.desktop "$HOME/.config/autostart"
fi

notify-send -t 10 "Notice: the auto update script has been updated on github, and cannot be auto updated" "If you were using beta 0.0.5 or later, please manually download the new auto update script form 'https://github.com/AspieSoft/fedora-setup/tree/0.1.0/assets/apps/aspiesoft-fedora-setup-updates' and replace the script in your local directory at '/etc/aspiesoft-fedora-setup-updates'"

echo "Notice: the auto update script has been updated on github, and cannot be auto updated" >> "$HOME/Desktop/aspiesoft-manual-update-notice.txt"
echo "" >> "$HOME/Desktop/aspiesoft-manual-update-notice.txt"
echo "If you were using beta 0.0.5 or later, please manually download the new auto update script form 'https://github.com/AspieSoft/fedora-setup/tree/0.1.0/assets/apps/aspiesoft-fedora-setup-updates' and replace the script in your local directory at '/etc/aspiesoft-fedora-setup-updates'" >> "$HOME/Desktop/aspiesoft-manual-update-notice.txt"
echo "" >> "$HOME/Desktop/aspiesoft-manual-update-notice.txt"
echo "This kind of update should not be as common once the script is out of beta (1.0.0)" >> "$HOME/Desktop/aspiesoft-manual-update-notice.txt"
