# Notes about Raspberry Pi Experiment

This page describes the main scenario for running the experiment


## 1 - Boot2Raspberry

First of all, we have to "dump" a working OS to an SD-Card and boot on it.

You'll find [here](http://blog.hypriot.com/downloads/) a set of [Rapsbian](http://www.raspbian.org) and Docker-ready images :
* Dowload the latest one (When writing this : ```hypriot-rpi-20150416-201537.img.zip```, based on jessie, with Docker 1.6.0)
* Dump it on your SD/Micro-SD card using these [Mac OS / Windows / Linux instructions](http://computers.tutsplus.com/articles/how-to-flash-an-sd-card-for-raspberry-pi--mac-53600)


## 2 - Pre-configuration of raspberries

### a - Set hostname

Seen that the default hostname is "black-pearl" for all freshly booted Hypriot images, we should set a custom one.

Edit (as root) the file ```/boot/occidentalis.txt``` at the line beginning with ```hostname```:
```bash
$ cat /boot/occidentalis.txt 
# hostname for your Hypriot Raspberry Pi:
hostname=your-name

# basic wireless networking options:
# wifi_ssid=your-ssid
# wifi_password=your-presharedkey
```

Note that a reboot is required. We'll do that at the end of the pre-configurations.

### b - Ensure your packages are up-to-date

Since we are on a debian jessie based OS, it's easy :
```bash
$ sudo apt-get update && sudo apt-get -y dist-upgrade
...
```

### c - Configure your Docker Daemon

You'll find [here](https://docs.docker.com/reference/commandline/cli/#daemon) the Docker's reference documentation. We want to :
* Make the daemon manageable from the outside world (e.g. bind it to a TCP socket)
* Let the local Docker client access the daemon (e.g. explicit the Unix socket's binding)
* Add some labels to this daemon to help Swarm schedule things later
* Configure our local registry (allowing insecure HTTP and enabling mirroring)

Edit (as root) the file ```/etc/default/docker```, on the line beginning with ```DOCKER_OPTS``` :
```bash
$ grep DOCKER_OPTS /etc/default/docker
...
DOCKER_OPTS="--storage-driver=overlay -D -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock --label arch=YOURARCH --insecure-registry REGISTRY_IP:REGISTRY_PORT --registry-mirror=http://REGISTRY_IP:REGISTRY_PORT"
``` 

Note to use your custom values for :
* REGISTRY_IP : your IP (or domain name if you have a full DNS resolution) of a running registry
* REGISTRY_PORT : port where your local registry is listening
* YOURARCH : armv6 (RPis A and B, all revisions) or armv7 (Rpis v2)


### d - Reboot your Raspberry

Simple as a ```sudo reboot```

## TODO...
