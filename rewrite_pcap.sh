#!/bin/sh

# This script reads an arbitrary pcap file containing UDP syslog data
# and rewrites the destination IP and MAC address to those of an adjacent running Docker container.
# Source addresses are similarly rewritten so that all original IPs are replaced with 
# IPs that are on the same subnet as the running Docker instance. 

# Note that this is done just to get the packets delivered; 
# it does not affect the original host IPs in message content
# e.g. "invalid login from 192.168.1.109" will not change

# give all of the other hosts a chance to get up and running
# important because we have to connect to a running service a few lines down
sleep 20

# Get IP/MAC/Subnet info for this running container
myip=$(ifconfig eth0 | grep inet | awk {'print $2'})
myether=$(ifconfig eth0 | grep ether | awk {'print $2'})
mysubnet=$(ifconfig eth0 | grep 'inet ' | awk {'print $2'} | awk -F. {'print $1"."$2".0.0"'})

# Get IP & MAC of adjacent Worker node running container
# First line establishes a connection to the worker so it's in arp cache
    # change 'worker' to an appropriate hostname for your environment - change docker-compose.yml too
    # change port 9000 to any listening TCP port on your syslog receiver
# Second line grep's worker's MAC from arp cache
workerip=$(python3 -c "import socket;addr1 = socket.gethostbyname('worker');s = socket.socket(socket.AF_INET, socket.SOCK_STREAM); s.connect((addr1,9000));print(addr1)")
workermac=$(arp -a | grep worker | awk {'print $4'})

# Guzzinta & Guzzoutta
input="/pcaps/syslog.pcap"
output="/pcaps/edited_syslog.pcap"


# Rewrite the original PCAP
# 192.168.1.107 was original Syslog server (destination)
# 192.168.1.0/24 was original subnet
# Rewrite destination MAC address & Fix checksums
/usr/bin/tcprewrite  \
 --dstipmap=192.168.1.107:$workerip \
 --srcipmap=192.168.1.0/24:$mysubnet/16 \
 --infile=$input \
 --outfile=$output \
 --enet-dmac=$workermac \
 --fixcsum


/usr/bin/tcpreplay -i eth0 --loop=1000000 $output &
tail -f /dev/null
exec "$@"