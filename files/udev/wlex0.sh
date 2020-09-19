#!/usr/bin/bash

if [ -f "/var/run/netns/openwrt-instance" ]; then
    # Configure Bridge
    ip link add br0 type bridge
    ip link set wlex0-veth0 master br0
    ip link set br0 up

    # Start Hostapd
    systemctl restart hostapd.service
fi