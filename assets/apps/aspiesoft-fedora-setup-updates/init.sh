#!/bin/bash

if ! [[ $(crontab -l) == *"# aspiesoft-fedora-setup-updates"* ]] ; then
  crontab -l | { cat; echo '0 2 * * * sudo bash /etc/aspiesoft-fedora-setup-updates/update.sh # aspiesoft-fedora-setup-updates'; } | crontab -
fi

sudo bash /etc/aspiesoft-fedora-setup-updates/update.sh
