#!/bin/sh

HOST_DIR=/host-datadir
PROXY_DIR=/var/cache/squid3
REGISTRY_DIR=/tmp/registry-dev

# Copy the squid data and apply rights
if [ -d "${HOST_DIR}/squid3" ];then
	#cp -r "${HOST_DIR}/squid3" "${PROXY_DIR}"
	rsync -av "${HOST_DIR}/squid3" $(dirname "${PROXY_DIR}")
fi
chown -R proxy:proxy "${PROXY_DIR}"
chmod -R 755 "${PROXY_DIR}"

# Copy the registry data and apply rights
if [ -d "${HOST_DIR}/registry-dev" ];then
	rsync -av "${HOST_DIR}/registry-dev" $(dirname "${REGISTRY_DIR}")
fi
