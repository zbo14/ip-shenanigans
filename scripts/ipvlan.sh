#!/bin/bash -e

if [ -z "$1" ]; then
    echo "Usage: ipvlan <iface>"
    exit 1
fi

# Delete existing namespaces
ip net del ns0 > /dev/null 2>&1
ip net del ns1 > /dev/null 2>&1

# Create network namespaces
ip net add ns0
ip net add ns1

# Create interfaces
ip l add link "$1" ipvl0 type ipvlan mode l2
ip l add link "$1" ipvl1 type ipvlan mode l2

# Add interfaces to namespaces
ip l set dev ipvl0 netns ns0
ip l set dev ipvl1 netns ns1

# Bring interfaces up
ip net exec ns0 ip l set dev ipvl0 up
ip net exec ns0 ip l set dev lo up
ip net exec ns1 ip l set dev ipvl1 up
ip net exec ns1 ip l set dev lo up

# Set up IP addresses for interfaces
ip net exec ns0 ip a add 192.168.1.100/24 dev ipvl0
ip net exec ns0 ip a add 127.0.0.1 dev lo
ip net exec ns1 ip a add 192.168.1.101/24 dev ipvl1
ip net exec ns1 ip a add 127.0.0.1 dev lo

# Ping ipvlan in first namespace from second
ip net exec ns1 ping 192.168.1.100
