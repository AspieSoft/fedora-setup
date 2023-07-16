#!/bin/bash

sudo ufw limit 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw default deny incoming
sudo ufw default allow outgoing

# install fail2ban
sudo dnf -y install fail2ban

if ! [ -f "/etc/fail2ban/jail.local" ]; then
  sudo touch "/etc/fail2ban/jail.local"
  echo '[DEFAULT]' | sudo tee -a "/etc/fail2ban/jail.local"
  echo 'ignoreip = 127.0.0.1/8 ::1' | sudo tee -a "/etc/fail2ban/jail.local"
  echo 'bantime = 3600' | sudo tee -a "/etc/fail2ban/jail.local"
  echo 'findtime = 600' | sudo tee -a "/etc/fail2ban/jail.local"
  echo 'maxretry = 5' | sudo tee -a "/etc/fail2ban/jail.local"
  echo '' | sudo tee -a "/etc/fail2ban/jail.local"
  echo '[sshd]' | sudo tee -a "/etc/fail2ban/jail.local"
  echo 'enabled = true' | sudo tee -a "/etc/fail2ban/jail.local"
fi

sudo systemctl enable fail2ban
sudo systemctl start fail2ban
