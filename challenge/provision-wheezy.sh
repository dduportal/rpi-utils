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
# Disable debug
# overlay storage seems best suited (TO TEST)
# No log at all to limit opened files and do not spend cpu cycle writing logs
# No SSL operation to not waste CPU
# No ipv6
# No userland proxy : less processes
# No container icc : no need to link

# TO TRY : 
 # --ip-forward=true                      Enable net.ipv4.ip_forward
 # --ip-masq=true                         Enable IP masquerading
 # --iptables=true                        Enable addition of iptables rules

echo 'DOCKER_OPTS="--debug=false --storage-driver=overlay \
	--userland-proxy=false -H tcp://0.0.0.0:2375 --ipv6=false \
	--tlsverify=false --tls=false --log-level=info --icc=false \
	--log-driver=none "' \
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
