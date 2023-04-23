#!/bin/bash

# Update system
sudo apt-get update && sudo apt-get upgrade -y

# Remove unnecessary packages
sudo apt-get autoremove -y

# Install core system components
sudo apt-get install kali-desktop-xfce -y

# Remove unnecessary configuration files
sudo apt-get purge kali-linux-wireless -y

# Remove additional packages
sudo apt-get clean && sudo apt-get autoclean

# Reboot Raspberry Pi
sudo reboot

