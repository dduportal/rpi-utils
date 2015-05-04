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


## 3 - Run basic Docker commands

## 4 - Play with Docker-compose

## 5 - Create Docker Swarm cluster

### Why ?

* If my Docker's Engine goes down, I want to run my containers on another engine,
* I want to run my container on the "right" engine, on my set of different servers.  

### What ?

* A webservice (the "swarm manager") will act as "application proxy".
* The docker clients will dial with this "manager" instead of dialing with Docker's engines
* Since it knows all the cluster's node, the "manager" will schedule your containers somewhere, dependening on a set of rules.

### How 

### a - Understand Discovery

As [stated by the Swarm's documentation](https://docs.docker.com/swarm/discovery/), we have different "discovering systems".
* "Docker Hub base" : this is the default one. Each node will contact the Docker Hub (external service) to register itself thru a unique token.
* "Static discovery" : just provide the list of node to your swarm manager. Hey come on, we're in 2015 !
* "3rd party discovery" : Swarm will just use a 3rd party system to store its knowledge of the cluster

We're gonna use the **"consul based discovery"** (which a 3rd party system)

### b - Bootstrap consul cluster

You have to create a consul server cluster, which will be responsible to store and share all the states (consul, swarm, healthchecks).

We have a lot of [documentation for that](https://www.consul.io/docs/guides/bootstrapping.html), so we'll keep it simple :
* **Non production setup** : we'll have only one consul server
* GUI : This server will also serve the [Web UI](https://www.consul.io/intro/getting-started/ui.html) to see easily our cluster state
* Network : we'll launch the server on the "shack" machine, at the host level, to not suffers [UDP network's related problem](https://github.com/progrium/docker-consul#issue-with-quickly-restarting-a-node-using-the-same-ip) 

On the host shack machine, first preapre ui and data dirs :
```bash
$ mkdir -p /tmp/consul/data
$ curl -L -o /tmp/consul/ui.zip https://dl.bintray.com/mitchellh/consul/0.5.0_web_ui.zip
$ unzip -o /tmp/consul/ui.zip -d /tmp/consul/
```

and launch the consul agent in alone server mode (**Discouraged in production**) :
```bash
$ consul agent -server -bootstrap-expect 1 -advertise YOURIP -data-dir /tmp/consul/data -ui-dir /tmp/consul/dist
...
```

You can access the Web UI, on the shack machine only, on [http://localhost:8500/ui](http://localhost:8500/ui), to visualize your Consul's cluster.

### c - Each Rpi node : launch consul local agent

Each node will have a local consul agent, connected to the global Consul's cluster.

Given that we are not on a pre-baked "shack" machine, how to install Consul ?

**There is a Docker image for that !**

Just run on each Rpi :
```bash
($ docker kill consul && docker rm -v consul if previously launched)
$ docker run --net=host --name consul -d dduportal/arm-consul:0.5.0 -server -advertise RPI_IP -join SHACK_IP
```

On the "shack" machine, the Web UI will reflect the new joined consul agents.

### d - Launching swarm nodes

On each Raspberry, we'll launch a swarm agent, that will monitor the local Docker's engine, and store its knowledge on the Consul cluster, thru the local consul agent.

On each node :
```bash
($ docker kill swarm && docker rm -v swarm if previously launched)
$ docker run -d --name swarm dduportal/arm-swarm:0.2.0 join --addr RPI_IP:DOCKER_PORT consul://RPI_IP:8500/swarm
```

You can validate :
* Thru the Web UI on the shack machine
* Running swarm in "listing mode" :
```bash
$ docker run --rm dduportal/arm-swarm:0.2.0 list consul://RPI_IP:8500/swarm
```

### e - Launch the swarm manager

This part is [currently a SPOF](https://github.com/docker/swarm/blob/master/ROADMAP.md#leader-election-distributed-state).

So we'll launch it on the shack machine :
```bash
($ docker kill swarmmanager && docker rm -v swarmmanager if previously launched)
$ docker run --name swarmmanager -d -p 10000:2375 swarm:0.2.0 manage consul://SHACK_IP:8500/swarm
```

Note that this is a webservice, so it has to be accessible (check your port forwarding on the shack machine if docker runs inside a VM) from the private network.

### f - Profit !

Point a Docker client to the manager IP and port, and start running containers across the cluster :
```bash
$ export DOCKER_HOST=tcp://SHACK_IP:10000
$ docker ps
$ docker version
$ docker info
$ docker run dduportal/rpi-alpine echo "Hello from $(hostname)"
$ docker run dduportal/rpi-alpine grep processor /proc/cpuinfo | wc -l #How many CPUs ?
...
```

