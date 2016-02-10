
class: center, middle

# Docker-Bel Meetup
## Swarm on Raspberry Pis

---

# Agenda

* 19h: Welcome & bootstrap
* 19h30: Talk from Dieter Reuter from Hypriot
* 20h: Workshop time !
* 22h: End of the workshop + drinks and snacks

---

# Welcome to the meetup !
## How to quickly bootstrap ?

1. Connect your laptop to the shared Wifi "Dadou’s MacBook Air" (dockerbel)

2. Insert the SD card (previously flashed), connect the Pi to Ethernet and
power it with micro-USB

3. Come at the "shack" to tell us which hostname you want to use. Be creative !

4. After we have configured your hostname, ssh to your host :
  ```
  $ ssh root@<your hostname>.local # Password is hypriot
  ```

5. Upgrade embedded docker tools :
  ```
  $ apt-get update && apt-get install --only-upgrade docker-hypriot docker-compose
  ```

---

class: center, middle

# Welcome Dieter Reuter from Hypriot
### Talk time !
![Hypriot](img/hypriot.png "Hypriot")

---

# Now let's workshop !
## Goal :

* We want to launch the Docker demo "voting app" on a cluster of Raspberry Pis.
  - Docker on ARM board ? Voting app ?

* This voting app will be launched on Swarm cluster.
  - How to bootstrap Swarm ?

* Workshop logistic : we'll group by 3 boards : 1 master, 2 nodes
  - Meet, Talk and Work together !

---

# Now let's workshop !
[Docker Voting app](https://github.com/docker/example-voting-app)

![Diagram](img/voting-app.png)

---

# Now let's workshop !
## ARM board ? Which image ?

HypriotOS helps us to run Docker : easy !
```
$ docker -v
Docker version 1.10.0, build 590d5108
```

but which image to run ?

```
$ docker run -ti --rm alpine:latest sh
exec format error
```

You have 2 good starting points :
```
$ docker run -ti --rm hypriot/rpi-alpine-scratch echo "Lightweight ARM image"
Lightweight ARM image

$ docker run -ti --rm resin/rpi-raspbian echo "Complete ARM image"
Complete ARM image
```

---

# Now let's workshop !
## ARM Voting App : mastering docker-compose

We made your life easy : an ARM voting app ready to go !

```
git clone https://github.com/jmMeessen/rpi-voting-app
```

* A generic `docker-compose.yml` using the DockerHub

* Extended by `dev-compose.yml` that will build images from sources

* Another extending with `workshop.yml` that will use a local private registry

---

# Now let's workshop !
## Physical architecture :

![phys-arch](./img/physical-arch.png)

---
* Start consul :
/consul agent -dev -ui -ui-dir=/web-ui -advertise=192.168.2.8 -bind=192.168.2.8 -client=192.168.2.8



---

* Stop docker :
systemctl stop docker
* Edit /etc/default/docker
