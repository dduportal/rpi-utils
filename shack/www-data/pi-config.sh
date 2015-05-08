#!/bin/sh
#
# This script will help to preconfigure a raspberry pi, 
#	booted on hypriot ARMed image (http://blog.hypriot.com/downloads/).
#	It is aimed to run the "rpi session" from github.com/dduportal.rpi-utils

KBD_LAYOUT=${1-fr}
SHACK_IP=${2-192.168.2.1}

set -e
set -u

# Configure local proxy (supposing it is on the provided IP)
echo "Acquire::http::Proxy \"http://${SHACK_IP}:3128\";" | sudo tee /etc/apt/apt.conf.d/proxy

# Update and upgrade safely packages (no kernel update !)
sudo apt-get update
sudo apt-get -y dist-upgrade
sudo apt-get install -y lxde git curl chromium

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
