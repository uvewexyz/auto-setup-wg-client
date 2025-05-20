#!/bin/sh

##############################################
### Easy setup Wireguard Client in OpenWRT ###
##############################################

# Set Variable #

# The WireGuard dir variable
WG_DIR="/etc/wireguard"

# The WireGuard interface variable
WG_IF="wg0"

##############################################
# You must choose between using the public IP 
# with the WG_SERV variable or using the domain 
# from your server WireGuard with the WG_DOM variable.
# Select one and comment on the not selected variable. 
# The default is using the WG_SERV variable. 
# If you use the WG_DOM, please uncomment in the "Add VPN peers" section too. 
# Example:
#
# 1. Using the public IP as endpoint server.
# WG_SERV="12.34.56.78"
# #WG_DOM="www.example.com"
# 2. Using the domain as endpoint:
# #WG_SERV="12.34.56.78"
# WG_DOM="www.example.com"
#
# Remember to pay attention in the variable WG_SERV and WG_DOM in "Add VPN peers" section.
#
##############################################

# The public IP of your server WireGuard
WG_SERV=""

# The domain of your server WireGuard
#WG_DOM="Your_Domain"

# The port of your server WireGuard
WG_PORT="51820"

# Matching with the WG ip interface in your server configuration!
WG_ADDR="10.10.20.5/24"

# Matching with the Server public key!
WG_SRV_PUB=""

# Network service variable
NET_SVC="/etc/init.d/network"

# Firewall service variable
FRW_SVC="/etc/init.d/firewall"

# The WAN interface variable
WAN_IF="$(uci show network.wan.device | awk -F"'" '{print $2}')"

# The WAN gateway variable
WAN_GTW="$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1 | sed 's/\.[0-9]\{1,3\}$/\.1/')"


# Install Packages #
echo "---------------------------------------------------------------";
echo "Check Wireguard packages";
sleep 2;
if opkg list-installed | grep wireguard > /dev/null 2>&1; then
    echo "Wireguard packages already installed, Next step installation"
    echo "Result:"
    echo "$(opkg list-installed | grep wireguard)"
    sleep 2
else
    echo "Wireguard packages not founds, let's install.."
    opkg update && opkg install wireguard-tools kmod-wireguard luci-proto-wireguard curl
    sleep 2
    echo "Wireguard packages successfully installed. Result:"
    echo "$(opkg list-installed | grep wireguard)"
fi


# Create WG Dir #
echo "---------------------------------------------------------------";
echo "Check Wireguard directory";
echo "---------------------------------------------------------------";
sleep 2;
if [ ! -d ${WG_DIR} ]; then
    echo "$WG_DIR directory not ready, let's create.."
    mkdir $WG_DIR
    echo "Successfully created $WG_DIR directory"
else
    echo "$WG_DIR directory already exists"
fi
sleep 2;


# Generate a key pair of private and public keys #
echo "---------------------------------------------------------------";
echo "Check a key pair of private and public keys";
echo "---------------------------------------------------------------";
sleep 2;
if [ -f $WG_DIR/wg.key ] && [ -f $WG_DIR/wg.pub ]; then
    echo "Key pair already exists.."
    # Client private key
    WG_CLN_KEY="$(cat $WG_DIR/wg.key)"
    # Client public key
    WG_CLN_PUB="$(cat $WG_DIR/wg.pub)"
    echo "Your private key: $WG_CLN_KEY"
    echo "Your public key: $WG_CLN_PUB"
else
    echo "Key pair not found, let's generate.."
    wg genkey | tee $WG_DIR/wg.key | wg pubkey > $WG_DIR/wg.pub
    echo "Successfully generated a key pairs. Result:"
    sleep 2
    # Client private key
    WG_CLN_KEY="$(cat $WG_DIR/wg.key)"
    # Client public key
    WG_CLN_PUB="$(cat $WG_DIR/wg.pub)"
    echo "Your private key: $WG_CLN_KEY"
    echo "Your public key: $WG_CLN_PUB"
fi
sleep 5;


# Setup Firewall #
echo "---------------------------------------------------------------";
echo "Let's Setup Firewall";
sleep 2;
uci rename firewall.@zone[0]="lan";
uci rename firewall.@zone[1]="wan";
uci add_list firewall.wan.network="${WG_IF}";
uci del_list firewall.wan.network="${WG_IF}";
uci commit firewall;
sleep 2;
echo "---------------------------------------------------------------";
echo "Firewall successfully configured. Result:"
echo "$(uci show firewall.wan.network)";
sleep 2;
echo "Restart the firewall service"
if eval $FRW_SVC status > /dev/null 2>&1; then
    echo "Firewall service state: Running"
    echo "Restarting firewall service"
    sleep 2
    eval $FRW_SVC restart &
    FRW_PID=$!
    wait $FRW_PID
    echo "Firewall service successfully restarted"
else
    echo "WTF, firewall service is dead, need to be fixed"
    exit 1
fi
echo "---------------------------------------------------------------";
sleep 2;


# Configure WG interface #                                                                                                                                         
echo "Let's configure Wireguard interface";
sleep 2;
uci -q delete network.${WG_IF};                                                                                                                                    
uci set network.${WG_IF}="interface";
uci set network.${WG_IF}.proto="wireguard";
uci set network.${WG_IF}.private_key="${WG_CLN_KEY}";
uci add_list network.${WG_IF}.addresses="${WG_ADDR}";
uci set network.${WG_IF}.metric="0";
uci set network.${WG_IF}.dns="1.1.1.1";
echo "---------------------------------------------------------------";
echo "Wireguard interface successfully configured. Result:";
echo "$(uci show network.${WG_IF})";
sleep 2;


# Configure WAN interface #
uci set network.wan.metric="20";
echo "---------------------------------------------------------------";
echo "Successfully setting metric in WAN interface. Result:";
echo "$(uci show network.wan.metric;)";
sleep 2;


# Add VPN peers #
echo "---------------------------------------------------------------";
echo "Let's add VPN peers";
sleep 2;
uci -q delete network.wgserver;
uci set network.wgserver="wireguard_${WG_IF}";
uci set network.wgserver.public_key="${WG_SRV_PUB}";
#uci set network.wgserver.endpoint_host="${WG_DOM}";
uci set network.wgserver.endpoint_host="${WG_SERV}";
uci set network.wgserver.endpoint_port="${WG_PORT}";
uci set network.wgserver.persistent_keepalive="25";
uci set network.wgserver.route_allowed_ips="1";
uci add_list network.wgserver.allowed_ips="0.0.0.0/0";
uci commit network;
echo "---------------------------------------------------------------";
echo "VPN peers successfully added. Result:";
echo "$(uci show network.wgserver)";
sleep 2;


# Restart the network service #
echo "---------------------------------------------------------------";
echo "Restart the network service"
if eval $NET_SVC status > /dev/null 2>&1; then
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
echo "---------------------------------------------------------------";
sleep 5;


# Configure Routing IP #
echo "Let's configure routing IP";
sleep 2;
echo "Check routing table before";
route -n | tee /tmp/routing_before$(date +%Y_%m_%d_%H_%M_%S).txt;
sleep 2;
ip route del default;
ip route add default dev $WG_IF;
ip route add 54.251.3.207/32 via $WAN_GTW dev $WAN_IF;
echo "---------------------------------------------------------------";
echo "Successfully configured routing IP";
echo "Result:";
echo "$(route -n)";
echo "---------------------------------------------------------------";
sleep 5;


# Restart WG Interface #
echo "Check Wireguard connection";
wg;
sleep 2;
echo "---------------------------------------------------------------";
echo "Copy line below to your server Wireguard config:";
echo "---------------------------------------------------------------";
echo "[Peer]";
echo "### OpenWRT VM";
echo "PublicKey = $WG_CLN_PUB";
echo "AllowedIPs = 10.10.20.5/32";
echo "After add the line above, restart the wg insterface in your server!";
echo "---------------------------------------------------------------";
read -p "If you have already added the line above, type 'y' to continue and type 'n' to exit and manually check: " RESPONSE;
if [ "$RESPONSE" == "y" ]; then
    echo "Continue to checking step"
    sleep 2
    echo "---------------------------------------------------------------"
    ifconfig $WG_IF
    sleep 5
    echo "---------------------------------------------------------------"
    curl ipinfo.io | tee /tmp/ipinfo$(date +%Y_%m_%d_%H_%M_%S).txt
    echo "---------------------------------------------------------------";
    sleep 5
    traceroute openwrt.org | tee /tmp/traceroute$(date +%Y_%m_%d_%H_%M_%S).txt
    sleep 2
    echo "---------------------------------------------------------------"
    echo "Checking step and installation successfully"
else
    echo "Exit... Bye!"
    exit 1
fi