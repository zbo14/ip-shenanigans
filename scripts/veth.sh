#!/bin/bash -e

if [ -z "$1" ]; then
    echo "Usage: veth <iface>"
    exit 1
fi

# Delete existing namespace and interface
ip net del ns > /dev/null 2>&1
ip l del veth0 > /dev/null 2>&1

# Create a network namespace
ip net add ns

# Add a virtual ethernet device to namespace
ip l add veth0 type veth peer name veth1
ip l set veth1 netns ns

# Set up IP addresses for interfaces
ip a add 10.200.200.1/24 dev veth0
ip net exec ns ip a add 10.200.200.2/24 dev veth1

# Bring interfaces up
ip l set veth0 up
ip net exec ns ip l set veth1 up

# Make traffic leaving namespace go through virtual ethernet device
ip net exec ns ip r add default via 10.200.200.1

# Enable IPv4 forwarding
sysctl -w net.ipv4.ip_forward=1

# Set iptables rules
iptables -t nat -F
iptables -F FORWARD

iptables -A FORWARD -i "$1" -o veth0 -j ACCEPT
iptables -A FORWARD -o "$1" -i veth0 -j ACCEPT
iptables -P FORWARD DROP

iptables -t nat -A POSTROUTING -s 10.200.200.0/24 -o "$1" -j MASQUERADE
