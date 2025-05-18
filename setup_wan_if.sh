#!/bin/sh

##############################################                                                                                                                     
###     Easy setup WAN in OpenWRT VM       ###                                                                                                                     
##############################################                                                                                        

# This script is used to set up a WAN interface in an OpenWRT VM.
# I will use WAN connection only for testing purposes.
echo "Saving all network informations and configurations before changes...";
sleep 2;
echo "Backup network configuration...";
cp /etc/config/network /etc/config/network.bak$(date +%Y%m%d%);
echo "Backup network configuration done, result: $(ls /etc/config/network.bak*)";
sleep 2;


echo "Show and save ip address information";
ip addr show | tee /tmp/ip_addr$(date +%Y%m%d%).txt;
echo "Show and save ip address information done, result: $(ls /tmp/ip_addr*)";
sleep 2;


echo "Show and save routing table";
route -n | tee /tmp/route$(date +%Y%m%d%).txt;
echo "Show and save routing table done, result: $(ls /tmp/route*)";
sleep 2;


# Set up WAN connection
echo "Setting up WAN connection...";
sleep 2;
uci set network.@device[0].name="wan";
uci del network.lan
uci set network.wan="interface"
uci set network.wan.device="eth0"
uci set network.wan.proto="dhcp"
uci commit network
echo "Successfully set up WAN connection, result:"
uci show network.wan;


echo "Restarting network service...";
NET_SVC="/etc/init.d/network"
if eval $NET_SVC status >/dev/null 2>&1; then
    echo "Network service state: Running";
    echo "Restarting network service";
    sleep 2s;
    eval $NET_SVC restart &;
    NET_PID=$!;
    wait $NET_PID;
    echo "Network service successfully restarted";
else
    echo "WTF, network service is dead, need to be fixed";
    exit 1
fi
sleep 5s;


echo "Check after configuration";
sleep 2s;


echo "Show route information:";
route -n
sleep 2s;


echo "Show ip address information:";
ip addr show
sleep 2s;


echo "Check ping connection";
ping -c 5 8.8.8.8
ping -c 5 google.com
sleep 2s;


echo "Set up WAN connection finished";