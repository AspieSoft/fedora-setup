#!/bin/bash

# add rpmfusion repos
waitForWifi sudo dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
waitForWifi sudo dnf -y install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo fedora-third-party enable
sudo fedora-third-party refresh
waitForWifi sudo dnf -y groupupdate core

# add flathub
waitForWifi sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# install media codecs
waitForWifi sudo dnf install -y --skip-broken @multimedia
waitForWifi sudo dnf -y groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin --skip-broken
waitForWifi sudo dnf -y groupupdate sound-and-video

# install repositories
waitForWifi sudo dnf -y install fedora-workstation-repositories
waitForWifi sudo dnf -y config-manager --set-enabled google-chrome

# import microsoft keys
waitForWifi sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
if ! test -f "/etc/yum.repos.d/vscode.repo" ; then
  echo '[code]' | sudo tee -a "/etc/yum.repos.d/vscode.repo"
  echo 'name=Visual Studio Code' | sudo tee -a "/etc/yum.repos.d/vscode.repo"
  echo 'baseurl=https://packages.microsoft.com/yumrepos/vscode' | sudo tee -a "/etc/yum.repos.d/vscode.repo"
  echo 'enabled=1' | sudo tee -a "/etc/yum.repos.d/vscode.repo"
  echo 'gpgcheck=1' | sudo tee -a "/etc/yum.repos.d/vscode.repo"
  echo 'gpgkey=https://packages.microsoft.com/keys/microsoft.asc' | sudo tee -a "/etc/yum.repos.d/vscode.repo"
fi

# import atom keys
waitForWifi sudo rpm --import https://packagecloud.io/AtomEditor/atom/gpgkey
if ! test -f "/etc/yum.repos.d/atom.repo" ; then
  echo '[Atom]' | sudo tee -a "/etc/yum.repos.d/atom.repo"
  echo 'name=atom' | sudo tee -a "/etc/yum.repos.d/atom.repo"
  echo 'baseurl=https://packagecloud.io/AtomEditor/atom/el/7/$basearch' | sudo tee -a "/etc/yum.repos.d/atom.repo"
  echo 'enabled=1' | sudo tee -a "/etc/yum.repos.d/atom.repo"
  echo 'gpgcheck=0' | sudo tee -a "/etc/yum.repos.d/atom.repo"
  echo 'repo_gpgcheck=1' | sudo tee -a "/etc/yum.repos.d/atom.repo"
  echo 'gpgkey=https://packagecloud.io/AtomEditor/atom/gpgkey' | sudo tee -a "/etc/yum.repos.d/atom.repo"
fi

waitForWifi sudo dnf -y check-update
