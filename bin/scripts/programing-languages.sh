#!/bin/bash

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

# add npm to current user
if ! [ -f "$HOME/.zshrc" ]; then
  sudo touch "$HOME/.zshrc"
fi
if ! [ -f "$HOME/.profile" ]; then
  sudo touch "$HOME/.profile"
fi
if ! grep -q 'export N_PREFIX="~/.npm"' "$HOME/.zshrc" ; then
  echo 'export N_PREFIX="~/.npm"' | sudo tee -a "$HOME/.zshrc"
fi
if ! grep -q 'export N_PREFIX="~/.npm"' "$HOME/.profile" ; then
  echo 'export N_PREFIX="~/.npm"' | sudo tee -a "$HOME/.profile"
fi
if ! [ -d "$HOME/.npm" ]; then
  sudo mkdir $(whoami) "$HOME/.npm"
  sudo chown -R $(whoami) "$HOME/.npm"
fi

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
