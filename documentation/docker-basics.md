
# Basic Docker commands

## Images and containers

* Images are just tar files, which are sets of other tar file. They are filesystem images. You can see which images you have with :
```bash
$ docker images
```

* Get new images with :
```bash
$ docker pull IMAGENAME
```
* Both images and containers have an UID in Hash64, AND a name which is a string
	* Images naming convention :
	  * Complete name is ```REPOSITORY:TAG```. Examples : 
	    * ```debian:wheezy```
	    * ```python:2.7```
	  * If no tag is supplied, Docker will use *latest*. Example : 
	    * ```busybox``` is exactly the same than ```busybox:latest```
	  * Images come from [Docker Hub](https://registry.hub.docker.com), unless you add the address of your own registry with a ```/``` separator. Examples : 
	    * ```registry.priv.org/my-app:latest```
	    * ```192.168.1.1:5000/arm-redis:0.3.0```
	  * You can use a namespace with a ```/``` separator before "REPOSITORY". Examples :
	    * ```ddupportal/arm-swarm:0.2.0```
	    * ```registry.priv.org/entity/my-jboss:latest```
	* Containers naming : [See that class :)](https://github.com/docker/docker/blob/master/pkg/namesgenerator/names-generator.go)

* Containers are the running entities that start from images. You can see which containers are (or have been) running on your system with :
```bash
$ docker ps # -a for all
```

* You can inspect images AND containers metadatas, providing UID or name to this unique command. :
```bash
$ docker inspect UID/or/NAME
```

## Running containers

* We can have 3 differents type of container runs (from an image) :
  - "One shot" running : run a single command and then exit :

    ```
	$ docker run debian:wheezy echo "Hello World !"
	```
  - "Interactive" : spawn a container and run a shell interactively inside :

  
    ```
	$ docker run -ti debian:wheezy /bin/bash
	```
  - "Daemon" : launch a container in background :

  
    ```
	$ docker run -d apache:2.4 /usr/bin/apache-ctl start
	```

* A container only have one command which is a simple Linux process. It can be specified at runtime or thru the images metadatas (default command) :
```bash
$ docker run -d redis:3.0.0
```

* Once a container hs been launched in background, you can spawn another process inside if you want to do some introspections tasks :
```bash
$ docker run --name webserver -d nginx
...
$ docker exec -ti webserver /bin/bash
bash-4.3 # ps aux | grep nginx
...
```

* Containers lifecycle : See below the all lifecycle, implying Docker's sub-commands like ```start```, ```create```, etc. 

![Docker's container lifecycle](./graphs/docker_containers_lifecycle.png)

## Containers network

* Default behaviour of Docker is to create a network stack for each container, and connect them to a virtual network. Access is done thru the host's interface named _docker0_ :

![Docker network](./graphs/docker_net.png)

* By default, you can access your container from the host or another local cotnainer, using the container's direct IP :
```bash
$ docker run -d --name webserver nginx:latest
...
$ docker inspect --format '{{ .NetworkSettings.IPAddress }}' webserver
172.17.0.15
$ curl -I --no-proxy='*' http://172.17.0.15
...
```

* If you want to give external access to your container, the preferred way is to use port forwarding :
  - 1st strategy is letting Docker select the port(s) to use :

    ```bash
    $ docker run --name=webserver -d -P nginx
    ...
    $ docker port webserver
    80/tcp -> 0.0.0.0:PORT
    443/tcp -> 0.0.0.0:PORT2
    $ curl --noproxy='*' -I http://127.0.0.1:PORT
    ...
    ```

  - 2nd is to specify the port (and the interface, and/or the level 3 protocol) to bind the forwarding to :

    ```bash
    $ docker run --name=webserver -d -p 80:10.0.2.15:10080 nginx
    ...
    $ docker port webserver
    80/tcp -> 10.0.2.15:10080
    $ curl --noproxy='*' -I http://10.0.2.15:10080
    ...
    ```

* Anyway, [they are other networking configurations](https://docs.docker.com/reference/run/#network-settings), it's moving [a lot those times](http://socketplane.io/blog/socketplane-excited-to-be-joining-docker-to-collaborate-with-networking-ecosystem/) :
  - Start a container on your host's network stack : 

    ```bash
    $ docker run --net=host ...
    ```
  - Start a container on another container's network stack : 

    ```bash
    $ docker run --net= container:ANOTHER_CONTAINER_ID ...
    ```
  - Start a container with no network : 

    ```bash
    $ docker run --net=none ...
    ```
  - Add custom DNS (host's ones will be use as fallback) : 

    ```bash
    $ docker run --dns 8.8.8.8 ...
    ```

* One powerful network functionnality of Docker is the "Containers linking". it allows 2 containers to know each others thru local DNS naming and environment variables :
```bash
$ docker run -d --name redissrv redis
...
$ docker run -ti --link redissrv:dbserver redis:3.0.0 env
# <Have a look to this content>
...
$ docker run -ti --link redissrv:dbserver redis:3.0.0 redis-cli -h dbserver
...

```

## Build you own images

## Playing with data volumes
