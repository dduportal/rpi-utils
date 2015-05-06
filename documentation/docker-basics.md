
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

* Docker use a "copy-on-write" underlying filesystem. Everything written inside a container is just a set of data blocks, virtualized as a "Linux Filesystem". We're talking about a stack of layers :

![Docker layers](http://xebia.github.io/docker-introduction/slides/img/docker-filesystems-busyboxrw.png)

```bash
$ docker images --tree
├─a8adec1c8256 Virtual Size: 4.93 MB Tags: dduportal/rpi-alpine:edge, dduportal/rpi-alpine:latest
│ ├─d0fbd61239a1 Virtual Size: 4.931 MB
│ │ └─f9774afcfa3c Virtual Size: 4.931 MB
│ │   └─80bd603c6503 Virtual Size: 50.78 MB
│ │     └─f4937bd913df Virtual Size: 56.93 MB
│ │       └─e5319849a634 Virtual Size: 56.93 MB Tags: composetest_web:latest

```

* Manually create an image - **This is bad practise** :
  1. run a container

    ```bash
    $ docker run -ti dduportal/rpi-alpine sh
    ```

  2. write something inside and terminate that container

    ```bash
    sh # echo "Hello" > /file.txt
    sh # exit
    $
    ```

  3. commit that container to create a new image (== a new set of layers)

    ```bash
    $ docker commit -m "Image with a new text file" JUST_TERMINATED_CONTAINER_ID myimage:1.0.0
    ```

  5. Run a new container based on the newly created image

    ```bash
    $ docker run myimage:1.0.0 cat /file.txt
    Hello
    $
    ```

* Automatize the image creation with a ```Dockerfile``` :

```bash
$ cat Dockerfile
FROM dduportal/rpi-alpine:edge
MAINTAINER your name here

RUN echo "Hello" > /another_file.txt
$ docker build -t myimage:2.0.0 ./
...
$ docker run myimage:2.0.0 cat /another_file.txt
Hello
```

* You can re-tag and push your images to registry - **AGAIN : bad practise ALERT**
```bash
$ docker tag myimage:2.0.0 myusername/myimage:2.0.0
...
$ docker push myusername/myimage:2.0.0
...
```

* **Good practises for building images**
  - Think of testing you images BEFORE building it (What's inside ? What's the wanted behaviour ?)
  - Implement testing with automated tools : [bats](https://github.com/sstephenson/bats), [serverspec](http://serverspec.org/), [cucumber with aruba](https://github.com/cucumber/aruba), etc.
  - Use the [automated builds of Docker Hub](https://docs.docker.com/docker-hub/builds/) : your user have to knwo what's inside your images
  - Be careful with the size of your images : [optimize](http://www.centurylinklabs.com/optimizing-docker-images/) and [squash](http://jasonwilder.com/blog/2014/08/19/squashing-docker-images/)
  - Use Continous Integration : [DockerHub with automated builds](https://docs.docker.com/docker-hub/builds/), [CircleCi](https://circleci.com/), [TravisCI](https://travis-ci.org/), [Jenkins](https://wiki.jenkins-ci.org/display/JENKINS/Docker+Plugin), etc.

## Playing with data volumes

* Copy-on-write is UBER cool for building and sharing images. But it's will destroy your I/Os when doing a lot writes : logs, tmp dirs, database storage dirs...

* There is a solution for that : [Docker's volumes](https://docs.docker.com/userguide/dockervolumes/). Tell Docker which path of your container are going to be "data volumes" :
  - At image level : with the ```VOLUME``` instruction in the Dockerfile :

     ```
     $ cat Dockerfile
     FROM centos:centos6
     ...
     VOLUME ["/var/log","/var/lib/mysql"]
     ``` 
  - At run time : with the ```-v``` switch of docker run command :

    ```bash
    $ docker run -v /app debian:jessie /bin/bash
    ```

* A "volume" is a folder or a file which is "bind-mounted" from the host inside the container. So it:
  - Won't be tracked down by the "copy-on-write" union filesystem
  - Won't be shared thru commit / build / images
  - Will have "host-native" I/Os performances
  - Its lifecyle and content will be bound to the Host : your host goes down, your data too ! **Do not forget backup and sync. systems**

* You can reach volume's content from your host :
```bash
$ docker run --name data-test -v /app busybox touch /app/file.txt
$ docker inspect --format '{{ .Volumes }}' data-test
map[/app:/mnt/sda2/var/lib/docker/vfs/dir/57b67b6f493a67daa1c617b4412a29a6e013833344b6e11139a0055014a797f1]
$ sudo ls -l /mnt/sda2/var/lib/docker/vfs/dir/57b67b6f493a67daa1c617b4412a29a6e013833344b6e11139a0055014a797f1
total 0
-rw-r--r--    1 root     root             0 May  6 11:56 file.txt
```

* You can share data beetween containers with **no overhead** :
```bash
$ docker run --volumes-from data-test busybox ls -l /app
total 0
-rw-r--r--    1 root     root             0 May  6 11:56 file.txt
```
