#/bin/sh

# https://raw.githubusercontent.com/dduportal/rpi-utils/hypr-challenge/challenge/provision-wheezy.sh
DOCKER_VERSION=1.8.1


# Update pkg and install usefull tools
apt-get update
apt-get dist-upgrade -y
apt-get install -y --no-install-recommends \
	btrfs-tools \
	git \
	htop \
	lsof \
	smem \
	strace \
	sysstat \
	vim

# Install latest docker
curl -L -O http://downloads.hypriot.com/docker-hypriot_${DOCKER_VERSION}-1_armhf.deb
dpkg -i ./docker-hypriot_${DOCKER_VERSION}-1_armhf.deb
rm -f ./docker-hypriot_${DOCKER_VERSION}-1_armhf.deb

# Configuration of Docker through systemd
service docker stop

mkdir -p /etc/systemd/system/docker.service.d

cat <<EOF >/etc/systemd/system/docker.service.d/custom-daemon-opts.conf
[Service]
LimitNOFILE=infinity
LimitNPROC=infinity
LimitSTACK=32768
ExecStart=
ExecStart=/usr/bin/docker daemon -H tcp://0.0.0.0:2375 \
        --storage-driver=overlay \
        --debug=false \
        --userland-proxy=false \
        --ipv6=false \
        --log-level=info \
        --log-driver=none \
        --ip-forward=false \
        --ip-masq=false \
        --iptables=false \
        --tls=false
EOF

service docker start

# Stop not so usefull service (for our case)
systemctl disable avahi-daemon.service
systemctl disable rsyslog.service
systemctl disable syslog.service
systemctl disable ntp.service
systemctl disable cron.service

# Add 1 Gb swap
mkdir /data
echo "Creating swap file, can take some times"
dd if=/dev/zero of=/data/swapfile bs=1M count=1024
mkswap /data/swapfile
chmod 0600 /data/swapfile
swapon /data/swapfile
sed -i '/swapfile/d' /etc/fstab
echo "/data/swapfile none swap sw 0 0" >> /etc/fstab
mount -a

# TODO : configure static IP to disable dhcclient
# auto lo
# iface lo inet loopback

# auto eth0
# iface eth0 inet static
#   address 192.168.1.20
#   network 192.168.1.0
#   netmask 255.255.255.0
#   gateway 192.168.1.1

# Use less memory as possible for gpu
echo "gpu_mem 16" > /boot/config.txt


# Configure Docker client
echo 'export DOCKER_HOST=tcp://127.0.0.1:2375' > /etc/profile.d/docker.sh
. /etc/profile

reboot 
