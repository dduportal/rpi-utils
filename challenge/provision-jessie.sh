#/bin/sh
# Yes, shell script, could be Ansible no ?

DOCKER_VERSION=1.8.2
export DOCKER_HOST=tcp://127.0.0.1:2375

set -e
set -u 
set -x 

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
mkdir -p /etc/systemd/system/docker.service.d
systemctl stop docker
cat <<EOF >/etc/systemd/system/docker.service.d/custom-daemon-opts.conf
[Service]
LimitNOFILE=infinity
LimitNPROC=infinity
LimitSTACK=32768
Environment="GOGC=10"
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
systemctl daemon-reload
systemctl start docker
sleep 5

docker pull hypriot/rpi-nano-httpd:latest

#Set the stack to 16 Kb
systemctl stop docker
sed -i 's/^LimitSTACK=.*$/LimitSTACK=16384/g' /etc/systemd/system/docker.service.d/custom-daemon-opts.conf
systemctl daemon-reload
systemctl start docker
sleep 5

docker images
grep -i stack /proc/$(ps aux | grep docker | grep -v grep | awk '{print $2}')/limits
xargs --null --max-args=1 echo < /proc/$(ps aux | grep docker | grep -v grep | awk '{print $2}')/environ | grep GOGC --color

systemctl enable docker

# Stop not so usefull service (for our case)
systemctl disable avahi-daemon.service
systemctl disable rsyslog.service
systemctl disable syslog.service
systemctl disable ntp.service
systemctl disable cron.service
systemctl disable dhclient.service

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

# Tune system parameters
cat <<EOF >/etc/sysctl.d/10-overcommit.conf
vm.overcommit_memory = 2
vm.overcommit_ratio = 100
vm.swappiness=100
vm.oom-kill = 0
EOF

# Static IP
cat <<EOF >/etc/network/interfaces
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address 192.168.1.20
  network 192.168.1.0
  netmask 255.255.255.0
  gateway 192.168.1.1
EOF


# Use less memory as possible for gpu
echo "gpu_mem 8" > /boot/config.txt


# Configure Docker client
echo "export DOCKER_HOST=${DOCKER_HOST}" > /etc/profile.d/docker.sh

# Configure access as root with ssh and insecure key
mkdir -p /root/.ssh
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key' \
  > /root/.ssh/authorized_keys
chmod 0700 /root/.ssh
chmod 0600 /root/.ssh/authorized_keys

reboot 
