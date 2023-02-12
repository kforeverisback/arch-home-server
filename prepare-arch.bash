#!/bin/bash

# Setup SSH
## Disable Password Auth
sed -r 's/(^# P|^#P|^P)asswordAuthentication.*/PasswordAuthentication no/g' sshd_config
## Change port to 420
## TODO Make it to Arg
sed -r 's/^Port 22|^#.*Port 22/Port 420/g' sshd_config

# Install YAY
pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
cd ../
rm -r yay-bin

# Install Docker
yay install -S docker docker-compose --noconfirm
sudo groupadd docker
sudo usermod -aG docker "$USER"
sudo systemctl enable docker.service
sudo systemctl enable containerd.service

# Install k3d