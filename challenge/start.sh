#!/bin/bash 
set -e

#DOCKER_IMAGE="hypriot/rpi-nano-httpd"
DOCKER_IMAGE="dduportal/rpi-nano-httpd"
P1=$1
P2=$2
MAXNR=${P1:="1"}
STARTNR=${P2:="0"}

docker build -t ${DOCKER_IMAGE} ./

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
    ${DOCKER_IMAGE} ${PORT}

done