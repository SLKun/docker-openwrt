#!/usr/bin/bash

if [ -f "/var/run/netns/openwrt-instance" ]; then
    # ## As Server ##
    # # Hostapd
    # # Stop Hostapd
    # systemctl stop hostapd.service

    # # Configure Bridge
    # ip link add br0 type bridge
    # ip link set wlex0-veth0 master br0
    # ip link set br0 up

    # # Start Hostapd
    # systemctl start hostapd.service

    ## As Client
    # Connect WiFi
    WPA_ON=$(ps aux | grep wpa_supplicant | wc -l) # 1: only grep, >1: other wpa_supplicant
    if [ "$WPA_ON" -eq 1 ]; then
        wpa_supplicant -B -i ${WWAN_IFACE} -c /etc/wpa_supplicant/wpa.conf
    fi

    # Configure macvlan
    ip link add eth2 link ${WWAN_IFACE} type macvlan mode passthru
    ip link set eth2 netns ${CONTAINER}
fi