# Shack

[Shack](http://en.wikipedia.org/wiki/Shack) ( the name is courtesy of [The captain](https://github.com/jmMeessen)) is a basic docker-compose project that help you bringing up docker-registry and http cache proxy to speed up your docker experiments, especially with Raspberry Pis.

## Requirements

* [Docker](https://docs.docker.com) 
* [Docker compose](https://docs.docker.com/compose/)
* [GNU Make](http://www.gnu.org/software/make/)
* (unhindered) Internet access !

## How to use ?

###  Basic usage

Just launch the ```make start```command, grab a coffee and let it run.
It will build and start all your services.

As a result, your services are accessible thru your Docker's host IP address :
```
$ make start
...
$ curl -L -I http://$(YOUR_DOCKER_HOST_IP):5000/v2/
HTTP/1.1 200 OK
...
Docker-Distribution-Api-Version: registry/2.0
...
$ curl -I --proxy http://$(YOUR_DOCKER_HOST_IP):3128 google.com
HTTP/1.1 302 Found
Cache-Control: private
...
Via: 1.1 c30a005049ae (squid/3.4.8)
```

You can stop all that with just :
```make stop```


### Data persistence

This setup uses the ["Data Volume Container"](https://docs.docker.com/userguide/dockervolumes/#creating-and-mounting-a-data-volume-container) pattern.

To persist, from host-level, the container related data (proxy cached content, docker registry images), you can use the command :

```make backup```

It will trigger a rsync-based backup of the data volume container locally.

Pros :
* This data will have a host bound lifecycle and not influenced by the docker-compose start/stop cycles
* You can reuse this data on another platform. It can become your own personnal and moveable cache

Cons :
* It makes things more complicated if you're a beginner
* It will make the ```make start``` slower (the time needed to load the existing data)

### Cleaning

Warning, if you clean without having backed-up the data, you will lose all your cache since it will delete the Data Volumes from Docker.

Just run ```make clean```

