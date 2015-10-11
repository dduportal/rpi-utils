#!/bin/bash 
set -e

START_SCRIPT="./start.sh"

SYNC_INTERVAL=50
TARGET=0
COUNTER=0

while [  true ]; do
  let TARGET=COUNTER+SYNC_INTERVAL
  
  # launch a batch of containers
  echo "=== Launching a batch of containers : FROM ${COUNTER} to ${TARGET}"
  sh ${START_SCRIPT} ${TARGET} ${COUNTER}

  # Clean caches and print memory status
  ssh -i ~/.vagrant.d/insecure_private_key root@192.168.1.20 "free -m && sync && echo 3 > /proc/sys/vm/drop_caches && free -m"

  # Upgrade counters
  COUNTER=$TARGET

done
