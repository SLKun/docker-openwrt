#!/bin/bash

function _usage() {
  echo "Could not find config file."
  echo "Usage: $0 [/path/to/openwrt.conf]"
  exit 1
}

function _cleanup() {
  kill wpa_supplicant
  docker stop $CONTAINER >/dev/null
  sudo rm -rf /var/run/netns/$CONTAINER
  sudo ip link del dev ${LAN_IFACE}.wan
}

# detect config file
SCRIPT_DIR=$(cd $(dirname $0) && pwd)
CONFIG_FILE=${1:-$SCRIPT_DIR/../openwrt.conf}
source $CONFIG_FILE 2>/dev/null || { _usage; exit 1; }

# connect WiFi
WWAN_ON=$(ip link | grep ${WWAN_IFACE})
if [[ -n "$WWAN_ON" ]]; then
  wpa_supplicant -B -i wlex0 -c ${SCRIPT_DIR}/../../wpa.conf
fi

# create and start docker
if docker inspect $BUILD_TAG>/dev/null 2>&1; then
  if docker inspect $CONTAINER >/dev/null 2>&1; then
    echo "Container Found."
  else
    docker create \
      --network none \
      --hostname OpenWRT \
      --cap-add NET_ADMIN \
      --cap-add NET_RAW \
      --sysctl net.netfilter.nf_conntrack_acct=1 \
      --sysctl net.ipv6.conf.all.disable_ipv6=0 \
      --sysctl net.ipv6.conf.all.forwarding=1 \
      --volume ${SCRIPT_DIR}/../persistent/etc:/etc \
      --name $CONTAINER $BUILD_TAG >/dev/null
  fi

  if docker inspect $CONTAINER >/dev/null 2>&1; then
    docker start $CONTAINER

    # Set network namespace 
    pid=$(docker inspect -f '{{.State.Pid}}' $CONTAINER)
    mkdir -p /var/run/netns
    ln -sf /proc/$pid/ns/net /var/run/netns/$CONTAINER
  fi
else
  echo "No Image Found."
fi

# Create MacVLAN and move into Docker
ip link add eth0 link ${LAN_IFACE} type macvlan mode bridge
ip link set eth0 netns ${CONTAINER}

# Move WAN into Docker
ip link set ${WAN_IFACE} netns ${CONTAINER}
ip netns exec ${CONTAINER} ip link set ${WAN_IFACE} name eth1

# Move WWAN into Docker
ip link add eth2 link ${WWAN_IFACE} type macvlan mode passthru
ip link set eth2 netns openwrt-instance

# Move WiFi into Docker
iw phy ${WLAN_PHY} set netns name ${CONTAINER}
ip netns exec ${CONTAINER} ip link set ${WLAN_IFACE} name wlan0
# iw phy ${WWAN_PHY} set netns name ${CONTAINER}
# ip netns exec ${CONTAINER} ip link set ${WWAN_IFACE} name wlan1

# Set Host Network
ip link add ${LAN_IFACE}.wan link ${LAN_IFACE} type macvlan mode bridge
ip link set ${LAN_IFACE}.wan up
dhcpcd -q ${LAN_IFACE}.wan

# Reload FW
docker exec -i $CONTAINER sh -c '
  for iptables in iptables ip6tables; do
    for table in filter nat mangle; do
      $iptables -t $table -F
    done
  done
  /sbin/fw3 -q restart'

# Before Exit
trap "_cleanup" EXIT
tail --pid=$pid -f /dev/null