#!/bin/bash

# install auto updates (for fedora)
sudo dnf -y install dnf-automatic
sudo sed -r -i 's/^apply_updates(\s*)=(\s*)(.*)$/apply_updates\1=\2yes/m' "/etc/dnf/automatic.conf"
systemctl enable --now dnf-automatic.timer
