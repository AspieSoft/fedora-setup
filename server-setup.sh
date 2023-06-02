#!/bin/bash

if ! [ "$1" = "-y" ]; then
  echo
  echo "This is the install for web servers."
  echo "If your looking for a gnome desktop setup, please run setup.sh instead."
  echo "This scripts installs common programing languages, clamav, and other useful tools for servers."
  echo "Note: This script will Not include auto updates for aspiesoft-fedora-setup from the github repo."
  echo
  read -n1 -p "Would you like to continue with the install (Y/n)? " input ; echo >&2

  if ! [ "$input" = "y" -o "$input" = "Y" -o "$input" = "" -o "$input" = " " ] ; then
    echo "install canceled!"
    exit
  fi
fi

echo "Starting Install..."
echo

# To log into sudo with password prompt
sudo echo

# improve dnf speed
echo "#Added for Speed" | sudo tee -a /etc/dnf/dnf.conf
echo "fastestmirror=True" | sudo tee -a /etc/dnf/dnf.conf
echo "max_parallel_downloads=5" | sudo tee -a /etc/dnf/dnf.conf
echo "defaultyes=True" | sudo tee -a /etc/dnf/dnf.conf
echo "keepcache=True" | sudo tee -a /etc/dnf/dnf.conf

sudo dnf -y update
sudo dnf -y makecache

# install python, c++, and java
sudo dnf -y install python python3 python-pip
sudo dnf -y install gcc-c++ make gcc
sudo dnf -y install java-1.8.0-openjdk.x86_64
sudo dnf -y install java-11-openjdk.x86_64
sudo dnf -y install java-latest-openjdk.x86_64

# install nodejs
sudo dnf -y install nodejs
sudo npm -g i npm
npm config set prefix ~/.npm

# add npm for new user
if ! [ -f "/etc/skel/.zshrc" ]; then
  sudo touch "/etc/skel/.zshrc"
fi
if ! [ -f "/etc/skel/.profile" ]; then
  sudo touch "/etc/skel/.profile"
fi
if ! grep -q 'export N_PREFIX="~/.npm"' "/etc/skel/.zshrc" ; then
  echo 'export N_PREFIX="~/.npm"' | sudo tee -a "/etc/skel/.zshrc"
fi
if ! grep -q 'export N_PREFIX="~/.npm"' "/etc/skel/.profile" ; then
  echo 'export N_PREFIX="~/.npm"' | sudo tee -a "/etc/skel/.profile"
fi

# install yarn, and git
sudo npm -g i yarn
sudo dnf -y install git

# install golang
sudo dnf -y install golang

# install clamav
sudo dnf -y install clamav clamd clamav-update
sudo systemctl stop clamav-freshclam
sudo freshclam
sudo systemctl enable clamav-freshclam --now

sudo dnf -y install cronie

sudo freshclam

# add quarantine folder
if ! [ -d "/VirusScan/quarantine" ]; then
  sudo mkdir -p /VirusScan/quarantine
  sudo chmod 0664 /VirusScan
  sudo chmod 2660 /VirusScan/quarantine
  sudo chmod -R 2660 /VirusScan/quarantine
fi

# fix clamav permissions
if grep -R "^ScanOnAccess " "/etc/clamd.d/scan.conf"; then
  sudo sed -r -i 's/^ScanOnAccess (.*)$/ScanOnAccess yes/m' "/etc/clamd.d/scan.conf"
else
  echo 'ScanOnAccess yes' | sudo tee -a "/etc/clamd.d/scan.conf"
fi

if grep -R "^OnAccessMountPath " "/etc/clamd.d/scan.conf"; then
  sudo sed -r -i 's#^OnAccessMountPath (.*)$#OnAccessMountPath /#m' "/etc/clamd.d/scan.conf"
else
  echo 'OnAccessMountPath /' | sudo tee -a "/etc/clamd.d/scan.conf"
fi

if grep -R "^OnAccessPrevention " "/etc/clamd.d/scan.conf"; then
  sudo sed -r -i 's/^OnAccessPrevention (.*)$/OnAccessPrevention no/m' "/etc/clamd.d/scan.conf"
else
  echo 'OnAccessPrevention no' | sudo tee -a "/etc/clamd.d/scan.conf"
fi

if grep -R "^OnAccessExtraScanning " "/etc/clamd.d/scan.conf"; then
  sudo sed -r -i 's/^OnAccessExtraScanning (.*)$/OnAccessExtraScanning yes/m' "/etc/clamd.d/scan.conf"
else
  echo 'OnAccessExtraScanning yes' | sudo tee -a "/etc/clamd.d/scan.conf"
fi

if grep -R "^OnAccessExcludeUID " "/etc/clamd.d/scan.conf"; then
  sudo sed -r -i 's/^OnAccessExcludeUID (.*)$/OnAccessExcludeUID 0/m' "/etc/clamd.d/scan.conf"
else
  echo 'OnAccessExcludeUID 0' | sudo tee -a "/etc/clamd.d/scan.conf"
fi

if grep -R "^User " "/etc/clamd.d/scan.conf"; then
  sudo sed -r -i 's/^User (.*)$/User root/m' "/etc/clamd.d/scan.conf"
else
  echo 'User root' | sudo tee -a "/etc/clamd.d/scan.conf"
fi


sudo mkdir "/etc/aspiesoft-auto-clamscan"

sudo touch "/etc/aspiesoft-auto-clamscan/init.sh"
echo '#!/bin/bash' | sudo tee -a "/etc/aspiesoft-auto-clamscan/init.sh"
echo '' | sudo tee -a "/etc/aspiesoft-auto-clamscan/init.sh"
echo 'if ! [[ $(crontab -l) == *"# aspiesoft-auto-clamscan"* ]] ; then' | sudo tee -a "/etc/aspiesoft-auto-clamscan/init.sh"
echo '  crontab -l | { cat; echo "0 2 * * * sudo bash /etc/aspiesoft-auto-clamscan/scan.sh # aspiesoft-auto-clamscan"; } | crontab -' | sudo tee -a "/etc/aspiesoft-auto-clamscan/init.sh"
echo 'fi' | sudo tee -a "/etc/aspiesoft-auto-clamscan/init.sh"

sudo touch "/etc/aspiesoft-auto-clamscan/scan.sh"
echo '#!/bin/bash' | sudo tee -a "/etc/aspiesoft-auto-clamscan/scan.sh"
echo '' | sudo tee -a "/etc/aspiesoft-auto-clamscan/scan.sh"
echo 'sudo nice -n 15 clamscan && sudo clamscan -r --bell --move="/VirusScan/quarantine" --exclude-dir="/VirusScan/quarantine" --exclude-dir="/home/$USER/.clamtk/viruses" --exclude-dir="smb4k" --exclude-dir="/run/user/$USER/gvfs" --exclude-dir="/home/$USER/.gvfs" --exclude-dir=".thunderbird" --exclude-dir=".mozilla-thunderbird" --exclude-dir=".evolution" --exclude-dir="Mail" --exclude-dir="kmail" --exclude-dir="^/sys" "/"' | sudo tee -a "/etc/aspiesoft-auto-clamscan/scan.sh"

sudo touch "/root/aspiesoft-auto-clamscan.service"
echo '[Unit]' | sudo tee -a "/root/aspiesoft-auto-clamscan.service"
echo 'Description=Init AspieSoft Auto Clamscan' | sudo tee -a "/root/aspiesoft-auto-clamscan.service"
echo 'service aspiesoft-auto-clamscan.service' | sudo tee -a "/root/aspiesoft-auto-clamscan.service"
echo 'partOf=aspiesoft-auto-clamscan.service' | sudo tee -a "/root/aspiesoft-auto-clamscan.service"
echo '' | sudo tee -a "/root/aspiesoft-auto-clamscan.service"
echo '[Service]' | sudo tee -a "/root/aspiesoft-auto-clamscan.service"
echo 'ExecStart=/etc/aspiesoft-auto-clamscan/init.sh' | sudo tee -a "/root/aspiesoft-auto-clamscan.service"
echo 'RemainAfterExit=yes' | sudo tee -a "/root/aspiesoft-auto-clamscan.service"
echo '' | sudo tee -a "/root/aspiesoft-auto-clamscan.service"
echo '[Install]' | sudo tee -a "/root/aspiesoft-auto-clamscan.service"
echo 'WantedBy=mulit-user.target' | sudo tee -a "/root/aspiesoft-auto-clamscan.service"
sudo chmod +x "/root/aspiesoft-auto-clamscan.service"
sudo ln -s "/root/aspiesoft-auto-clamscan.service" "/etc/rc.d/aspiesoft-autoclam-scan.service"


# auto updates
sudo dnf -y install dnf-automatic
sudo sed -r -i 's/^apply_updates(\s*)=(\s*)(.*)$/apply_updates\1=\2yes/m' "/etc/dnf/automatic.conf"
systemctl enable --now dnf-automatic.timer


sudo dnf -y update
sudo dnf clean all

echo "Install Finished!"
