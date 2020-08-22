#!/bin/bash 

function _usage() {
  echo "Could not find config file."
  echo "Usage: $0 [/path/to/openwrt.conf]"
  exit 1
}

function _cleanup() {
  # recovery route
  sudo ip addr add 192.168.100.250/24 dev enin0
  # stop docker and netns
  sudo docker stop $CONTAINER >/dev/null
  sudo rm -rf /var/run/netns/$CONTAINER
}

# detect config file
SCRIPT_DIR=$(cd $(dirname $0) && pwd)
CONFIG_FILE=${1:-$SCRIPT_DIR/../openwrt.conf}
source $CONFIG_FILE 2>/dev/null || { _usage; exit 1; }

# connect WiFi
WWAN_ON=$(ip link | grep ${WWAN_IFACE} | wc -l)
WPA_ON=$(ps aux | grep wpa | wc -l)
if [ "$WWAN_ON" -eq 1 ] && [ "$WPA_ON" -eq 1 ]; then
  wpa_supplicant -B -i ${WWAN_IFACE} -c ${SCRIPT_DIR}/../../wpa.conf
fi

# create and start docker
if docker inspect $BUILD_TAG>/dev/null 2>&1; then
  if ! docker inspect $CONTAINER >/dev/null 2>&1; then
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
  
  docker start $CONTAINER

  # Set network namespace 
  pid=$(docker inspect -f '{{.State.Pid}}' $CONTAINER)
  mkdir -p /var/run/netns
  ln -sf /proc/$pid/ns/net /var/run/netns/$CONTAINER
else
  echo "No Image Found."
  exit
fi

# Connect LAN
ip link add eth0 link ${LAN_IFACE} type macvlan mode passthru
ip link set eth0 netns ${CONTAINER}

# Connect WAN
ip link add eth1 link ${WAN_IFACE} type macvlan mode passthru
ip link set eth1 netns ${CONTAINER}

# Connect WWAN
usb_modeswitch -K -v 0bda -p 1a2b
ip link add eth2 link ${WWAN_IFACE} type macvlan mode passthru
ip link set eth2 netns openwrt-instance

# Move WLAN
iw phy ${WLAN_PHY} set netns name ${CONTAINER}
ip netns exec ${CONTAINER} ip link set ${WLAN_IFACE} name wlan0
# iw phy ${WWAN_PHY} set netns name ${CONTAINER}
# ip netns exec ${CONTAINER} ip link set ${WWAN_IFACE} name wlan1

# Set Host Network
ip link add veth0 type veth peer name veth1
ip link set veth0 up

ip link set veth1 netns ${CONTAINER}
ip netns exec ${CONTAINER} ip link set veth1 up

ip addr add 192.168.100.250 dev veth0
ip route add 192.168.100.1 dev veth0
ip route add default via 192.168.100.1 dev veth0

ip route del 192.168.100.0/24 dev enin0
ip route del 192.168.100.1 dev veth0
ip addr del 192.168.100.250/24 dev enin0

# Reload FW
docker exec -i $CONTAINER sh -c '
  for iptables in iptables ip6tables; do
    for table in filter nat mangle; do
      $iptables -t $table -F
    done
  done
  /sbin/fw3 -q restart'

# Wait for exit
trap "_cleanup" EXIT
tail --pid=$pid -f /dev/null
