#!/bin/sh
rsync -av /var/cache/squid3 /host-datadir/
rsync -av /tmp/registry-dev /host-datadir/
