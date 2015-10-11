#!/bin/bash 
set -e

DOCKER_IMAGE="hypriot/rpi-nano-httpd:latest"
P1=$1
P2=$2
MAXNR=${P1:="1"}
STARTNR=${P2:="0"}


COUNTER=$STARTNR
while [  $COUNTER -lt $MAXNR ]; do
  let COUNTER=COUNTER+1 
  let PORT=10000+COUNTER
  echo COUNTER=$COUNTER, PORT=$PORT

  docker run \
    -d \
    --read-only \
    --log-driver="none" \
    --name=WebServer-$PORT \
    --net=host \
    --ipc=host \
    --uts=host \
    ${DOCKER_IMAGE} /httpd ${PORT}
done
