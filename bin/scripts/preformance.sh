#!/bin/bash

# install preload
echo " - installing preload..."
sudo dnf -y copr enable elxreno/preload
sudo dnf -y install preload
sudo systemctl start preload
sudo systemctl enable preload

# install tlp
echo " - installing tlp..."
sudo dnf -y install tlp-rdw
sudo systemctl start tlp
sudo systemctl enable tlp
sudo tlp start

# install thermald
echo " - installing thermald..."
sudo dnf -y install thermald
sudo systemctl start thermald
sudo systemctl enable thermald


#todo: consider adding for an optional preformance mode (power mode)
#sudo dnf install gnome-power-manager power-profiles-daemon


# disable time wasting startup programs
echo " - disabling time wasting startup programs ..."
sudo systemctl disable NetworkManager-wait-online.service
sudo systemctl disable systemd-networkd.service
sudo systemctl disable accounts-daemon.service
sudo systemctl disable debug-shell.service
sudo systemctl disable nfs-client.target
sudo systemctl disable remote-fs.target

sudo dnf -y --noautoremove remove dmraid device-mapper-multipath
