#/bin/sh

# Update pkg and install usefull tools
apt-get update
apt-get dist-upgrade -y
apt-get install -y --no-install-recommends \
	git \
	htop \
	strace \
	systat \
	vim

# Install latest docker
curl -L -O http://downloads.hypriot.com/docker-hypriot_1.7.1-1_armhf.deb
dpkg -i ./docker-hypriot_1.7.1-1_armhf.deb

# Configure Docker
/etc/init.d/docker stop
echo > /etc/default/docker
echo 'DOCKER_OPTS="--debug=false --storage-driver=overlay --userland-proxy=false -H tcp://0.0.0.0:2375 --ipv6=false --tlsverify=false --tls=false --log-level=info --icc=false"' \
	> /etc/default/docker
/etc/init.d/docker start

# Fetch the git repository
rm -rf /rpi-utils
git clone -b hypr-challenge https://github.com/dduportal/rpi-utils /rpi-utils
chmod a+x -R /rpi-utils
