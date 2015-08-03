#/bin/sh

# https://raw.githubusercontent.com/dduportal/rpi-utils/hypr-challenge/challenge/provision-wheezy.sh

# Update pkg and install usefull tools
apt-get update
apt-get dist-upgrade -y
apt-get install -y --no-install-recommends \
	git \
	htop \
	lsof \
	strace \
	sysstat \
	vim

# Install latest docker
curl -L -O http://downloads.hypriot.com/docker-hypriot_1.7.1-1_armhf.deb
dpkg -i ./docker-hypriot_1.7.1-1_armhf.deb
rm -f ./docker-hypriot_1.7.1-1_armhf.deb

# Configure Docker Engine
/etc/init.d/docker stop
echo > /etc/default/docker

echo 'DOCKER_OPTS="--debug=false --storage-driver=overlay \
	--userland-proxy=false -H tcp://0.0.0.0:2375 --ipv6=false \
	--tlsverify=false --tls=false --log-level=info  \
	--log-driver=none --ip-forward=false --ip-masq=false --iptables=false"' \
	> /etc/default/docker

# Remove ulimit from start script
/etc/init.d/docker start
/etc/init.d/rsyslog stop # Gain ~ 30 Mb of memory

# Configure Docker client
echo 'export DOCKER_HOST=tcp://127.0.0.1:2375' > /etc/profile.d/docker.sh
. /etc/profile

# Fetch the git repository
rm -rf /rpi-utils
git clone -b hypr-challenge https://github.com/dduportal/rpi-utils /rpi-utils
chmod a+x -R /rpi-utils
