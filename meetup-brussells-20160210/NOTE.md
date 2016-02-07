# Notes regarding RPI Docker meetup

## High level goals
Goal of the meetup : launch the "voting app" demo of docker with the docker
stack : Machine, Engine, Compose and Swarm. The hardware platform will be
Raspberry Pi based, but can be any Docker host type compatible with Hypriot OS.

## Target audience
The target audience is docker beginners. Audience should at least understand
basics of Unix commandline (ssh access, options/arguments, basic command,
  text editing )

## High level steps
The building steps will follow the OSI stack methodology : layered, from
hardware setup to end user view at logical application level

### Hardware setup
#### Main nodes
Raspberry Pi or HypriotOs- compliant board.
* Each one must have a 8Go Sd card (or micro SD) with the latest HypriotOs
(http://blog.hypriot.com/downloads/) dumped onto.
* We will use wired Ethernet to connect to network
* AC will be provided by the micro-USB port
* No keyboard/mouse/hdmi/screen needed


#### Shack

The Shack will be the "utility" machine. It will have those roles :
* Allow Pis to access internet
* Provide a local cache for Docker images used
* Provide utilities services like Consul Server
* Show the slides to audience (switch between slides / Consul UI / Terminal
  must be quick and easy for presenter)

The Shack must have at least one wifi access to the web, and be able to
share web to its Ethernet wire (See Network section below)

#### Network

Our network will have those constraints :
* web access through the shack routing
* Wired part, need of switched, for the ARM boards like Pis, and audience
machines that will be used to access Pis.
* If possible, wifi access for audience laptop that do not have ethernet
connectivity.

We will use a Mac laptop as Shack machine :
* airport (integrated wifi) will be used to share private network for laptop
* Usb-ethernet adaptor for wired connectivity
* A Mac Os compatible Usb dongle for wifi (web access )

### Logical setup

This part will take care of explaining steps in details for the logical part

#### Network

The Shack must be started, connected, and have its network sharing
ability enabled :
* IP forwarding from Web interface to all others
* DHCP server started

In our case, we will use Mac OS Internet sharing ability that will create a
virtual private network ( by default 192.168.2.0/24) across multiple physical
network, which is perfect for us. Do not forget to configure a password for
airport sharing.

Then, connect all laptop by Wifi, to the configured Airport, and the Pis to
the wired network.

If you want to check the cartography of network :
* Use of ```nmap 192.168.2.0/24``` from any machine of this network
* In MacOS, you can see the internal DHCP server leases in the
file ```/private/var/db/dhcpd_leases```
* Combination of both : check which adresses leased are still in use :

  `grep ip_address /private/var/db/dhcpd_leases | cut -d= -f2 | nmap -iL - -sn`

You can check that the laptops, once having a 192.168.2.x address
distributed, can reach the web.


#### Shack configuration

Shack must provide those services :
* Local Docker private registry with the images preloaded on `192.168.2.1:5000`
  * Voting app demo images (5) : postgres, result, voting, hypriot/rpi-redis and worker
  * hypriot/rpi-alpine-scratch to playground
  * hypriot/rpi-swarm:1.1.0 to try latest swarm
* HTTP server on http://192.168.2.1 used to provide local downloads for :
  * Vagrant ssh keys (pub and priv)
  * docker-machine binaries with hypriot driver
  * MAYBE ?? docker-compose and docker-hypriot latest packages


#### ARM Boards OS configuration

Here are the "HypriotOS" base instructions to allow further configurations
(manual or docker-machine).m

First step is to connect to the machine, and do the minimalistic
configuration possible :
* Default user/password can be pi/raspberry or root/hypriot
* Edit /boot/occidentalis to ensure you have a uniq hostname instead of
black-pearl (Need a reboot to be applied)
* Add a ssh key pair to avoid typing password in future command.
I propose to use vagrant insecure key for now :
  * From https://github.com/mitchellh/vagrant/tree/master/keys
  * Add public key to your Pi machine :
    `curl --silent -L https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub >> /home/pi/.ssh/authorized_keys`
  * Add private key to you laptop :
    `curl -L -o ~/.ssh/id_vagrant_insecure https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant`
  * Test by remotely rebooting the pi with ssh. From you laptop :
    `ssh -i ~/.ssh/id_vagrant_insecure pi@<IP OF YOUR PI> sudo reboot now`

#### Docker engine configuration

WIP : Idea is to use the docker-machine with the driver hypriot from
(https://docs.docker.com/machine/reference/config/).
We have to "Create" a docker-machine from your laptop with
some custom docker configurations.

Docker-machine have a set of practical commands to help us configuring
the docker engines :
* `create` (create a new remote docker machine, with the flag --engine-opt) :
https://docs.docker.com/machine/reference/create/
* `config` (show the remote docker engine configuration):
https://docs.docker.com/machine/reference/config/
* `provision` (Re-apply configuration in case of problem ):
https://docs.docker.com/machine/reference/provision/

Docker Engine configurations flags can be reviewed from the documentation :
https://docs.docker.com/engine/reference/commandline/daemon/

What has to be configured :
*  Insecure access to the local private registry (http://192.168.2.1:5000)
used for caching, from the shack
* Daemon listening to HTTP : `-H tcp://0.0.0.0:2375`
(needed for remote docker commands)
* Configure the overlay network capability using the `--cluster-store` option.
It will use the `consul://<Ip of pi master>:8500` address to use the consul server of
the shack. It must be used in conjunction with `--cluster-advertise=eth0:2375`
* [Not mandatory - maybe to try the new config hot-reload for daemon] :
Configure the labels used for this engine

Even if docker-machine has capabilities for swarm, i want us to use "manual"
bootstrap to understand well how it works. So no more configuration are needed.

#### Swarm configuration
TODO
##### A bit of organization
We need to make Pis working by 3 at least :
* a master node that will run consul and swarm manager
* 2 (or more) nodes that will run the containers
* The nodes will be used as swarm backups manager in case of failure
to demonstrate HA capability

Start consul server consul server on the master with UI
on `<Ip of pi master>`. Launch it with :
  `docker run -d --net=host hypriot/rpi-consul agent -dev -ui -ui-dir=<PATH TO UI DIR>
   -advertise <Ip of pi master> -bind <Ip of pi master> -client <Ip of pi master>`

##### Agents

* Pull latest swarm docker image arm 1.1.0 from local registry
* Launch swarm agent with join :
  `docker run -d --restart=always --name=swarm-agent  hypriot/rpi-swarm:1.1.0 join --advertise $(ip addr|awk '/eth0/ && /inet/ {gsub(/\/[0-9][0-9]/,""); print $2}'):2375 consul://<Ip of pi master>:8500`
* Check the logs !
* Check in consul UI in Key/Value, docker -> swarm -> nodes

##### Manager
* Launch swarm manager on the master pi :
 `docker run -d -p 10000:6000 hypriot/rpi-swarm -H 0.0.0.0:6000 consul://<Ip of pi master>:8500 `
* Check the logs !
* Test it from laptop :
 `docker -H <Ip of pi master>:10000 info`
