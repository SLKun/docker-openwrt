#!/usr/bin/bash

if [ -f "/var/run/netns/openwrt-instance" ]; then
    ip link add eth1 link enex0 type macvlan mode passthru
    ip link set eth1 netns openwrt-instance
fi
