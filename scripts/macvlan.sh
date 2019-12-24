#!/bin/bash -e

if [ -z "$1" ]; then
    echo "Usage: macvlan <iface>"
    exit 1
fi

# Delete existing namespaces
ip net del ns0 > /dev/null 2>&1
ip net del ns1 > /dev/null 2>&1

# Create network namespaces
ip net add ns0
ip net add ns1

# Create interfaces
ip l add link "$1" macvl0 type macvlan mode bridge
ip l add link "$1" macvl1 type macvlan mode bridge

# Add interfaces to namespaces
ip l set dev macvl0 netns ns0
ip l set dev macvl1 netns ns1

# Bring interfaces up
ip net exec ns0 ip l set dev macvl0 up
ip net exec ns0 ip l set dev lo up
ip net exec ns1 ip l set dev macvl1 up
ip net exec ns1 ip l set dev lo up

# Set up IP addresses for interfaces
ip net exec ns0 ip a add 192.168.1.100/24 dev macvl0
ip net exec ns0 ip a add 127.0.0.1 dev lo
ip net exec ns1 ip a add 192.168.1.101/24 dev macvl1
ip net exec ns1 ip a add 127.0.0.1 dev lo

# Ping macvlan in first namespace from second
ip net exec ns1 ping 192.168.1.100
