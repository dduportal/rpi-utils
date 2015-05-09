#!/bin/sh
#
# This script will help to preconfigure a raspberry pi, 
#	booted on hypriot ARMed image (http://blog.hypriot.com/downloads/).
#	It is aimed to run the "rpi session" from github.com/dduportal.rpi-utils

KBD_LAYOUT=${1-fr}
SHACK_IP=${2-192.168.2.1}

# Configure local proxy if explicitely provided
if [ -n "${2}" ]; then
	echo "Acquire::http::Proxy \"http://${SHACK_IP}:3128\";" | sudo tee /etc/apt/apt.conf.d/proxy
fi

set -e
set -u

# Update and upgrade safely packages (no kernel update !)
export DEBIAN_FRONTEND noninteractive
sudo apt-get update
sudo apt-get -y dist-upgrade
sudo apt-get install -y --no-install-recommends lxde git curl chromium lightdm xserver-xorg

# Autolog to the pi user at boot-startx
sudo sed -i 's/#autologin-user=/autologin-user=pi/g' /etc/lightdm/lightdm.conf

# Disable IPv6 and wireless net interfaces
sudo sed -i '/inet6/d' /etc/network/interfaces
sudo sed -i '/wlan/d' /etc/network/interfaces
sudo sed -i '/wpa/d' /etc/network/interfaces

# Disable (for tty) the kernel verbose messages
sudo dmesg -n 1
echo 'sudo dmesg -n 1' | sudo tee -a "/etc/rc.local"

# Set  keyboard layout
sudo sed -i 's/^XKBLAYOUT=.*$/XKBLAYOUT="'"${KBD_LAYOUT}"'"/g' /etc/default/keyboard

# Configure the Docker daemon
DOCKER_CONFIG="DOCKER_OPTS=\"--storage-driver=overlay -D -H \
tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock \
--insecure-registry ${SHACK_IP}:5000 \
--registry-mirror=http://${SHACK_IP}:5000\""
sudo sed -i "/DOCKER_OPTS/d" /etc/default/docker
echo $DOCKER_CONFIG | sudo tee -a /etc/default/docker
