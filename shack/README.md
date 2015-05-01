# Shack

[Shack](http://en.wikipedia.org/wiki/Shack) ( the name is courtesy of [The captain](https://github.com/jmMeessen)) is a basic docker-compose project that help you bringing up docker-registry and http cache proxy to speed up your docker experiments, especially with Raspberry Pis.

## Requirements

* [Docker](https://docs.docker.com) 
* [Docker compose](https://docs.docker.com/compose/)
* [GNU Make](http://www.gnu.org/software/make/)
* Internet access !

## How to use ?

###  Basic usage

Just launch the ```make start```command, grab a coffee and let it run.
It will build and start all your services.

Then you're service are accessible thru you're Docker's host IP address :
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

It uses the pattern of the ["Data Volume Container"](https://docs.docker.com/userguide/dockervolumes/#creating-and-mounting-a-data-volume-container).

To persist, at your host-level, the inside data (proxy cached content, docker registry images) there is a command for that :

```make backup```

It will make a rsync-based backup of the data volume container locally.

Pros :
* This data will have a lifecycle bound to your host and not from docker-compose
* You can reuse this data to another platform and make you own personnal and moveable cache

Cons :
* It makes things more complicated if you're a beginner
* It will the ```make start``` slower (time of loading existing data)

### Cleaning

Be careful, if you clean without having backed up the data, you'll lose all your cache since it'll delete the Data Volumes from Docker.

Just run ```make clean```

