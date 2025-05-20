#!/bin/sh

##############################################                                                                                                                     
###     Easy setup WAN in OpenWRT VM       ###                                                                                                                     
##############################################                                                                                        

# This script is used to set up a WAN interface in an OpenWRT VM.
# I will use WAN connection only for testing purposes.
echo "-----------------------------------------------------";
echo "Saving all network informations and configurations before changes...";
sleep 2;
echo "Backup network configuration...";
cp /etc/config/network /tmp/network$(date +%Y_%m_%d_%H_%M_%S).bak;
echo "-----------------------------------------------------";
echo "Backup network configuration done. Result:"
echo "$(ls /tmp/network*)";
echo "------------------------------------------------------";
sleep 5;

echo "Show and save ip address information";
echo "-----------------------------------------------------";
ip addr show | tee /tmp/ip_addr$(date +%Y_%m_%d_%H_%M_%S).txt;
echo "Show and save ip address information done. Result:" 
echo "$(ls /tmp/ip_addr*)";
echo "------------------------------------------------------";
sleep 5;

echo "Show and save routing table";
echo "-----------------------------------------------------";
route -n | tee /tmp/route$(date +%Y_%m_%d_%H_%M_%S).txt;
echo "Show and save routing table done. Result:"
echo "$(ls /tmp/route*)";
echo "------------------------------------------------------";
sleep 5;



# Set up WAN connection
echo "Setting up WAN connection...";
echo "-----------------------------------------------------";
sleep 2;
uci -q set network.@device[0].name="wan";
uci -q del network.lan;
uci -q set network.wan="interface";
uci -q set network.wan.device="eth0";
uci -q set network.wan.proto="dhcp";
uci -q commit network;
echo "-----------------------------------------------------";
echo "Successfully set up WAN connection. Result:"
uci show network.wan;
sleep 5;
echo "-----------------------------------------------------";

# Restart the network service
echo "Restarting network service...";
echo "-----------------------------------------------------";
NET_SVC="/etc/init.d/network"
if eval $NET_SVC status >/dev/null 2>&1; then
    echo "Network service state: Running"
    echo "Restarting network service"
    sleep 2
    eval $NET_SVC restart &
    NET_PID=$!
    wait $NET_PID
    echo "Network service successfully restarted"
else
    echo "WTF, network service is dead, need to be fixed"
    exit 1
fi
sleep 5;

echo "-----------------------------------------------------";
echo "Show route information:";
route -n;
sleep 5;

echo "------------------------------------------------------";
echo "Show ip address information:";
ip addr show eth0
sleep 5;

echo "------------------------------------------------------";
echo "Check ping connection";
ping -c 3 8.8.8.8
sleep 8;
ping -c 3 google.com
sleep 5;

echo "------------------------------------------------------";
echo "Set up WAN connection finished";