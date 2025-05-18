#!/bin/sh


##############################################                                                                                                                     
### Easy setup Wireguard Client in OpenWRT ###                                                                                                                     
##############################################                                                                                        


# Set Variable #                                                                                                                                                   
WG_DIR="/etc/wireguard"                                                                                                                                            
WG_IF="wg0"                                                                                                                                                        
WG_SERV="54.251.3.207"                                                                                                                                             
# Pilih salah satu mau pakai IP Publik atau Domain! #                                                                                                              
# WG_DOM="Your_Domain"                                                                                                                                             
WG_PORT="51820"
WG_ADDR="10.10.20.5/24" # Sesuaikan dengan IP Interface WG di Server!
WG_CLN_KEY="$(cat $WG_DIR/wg.key)" # Client private key
WG_CLN_PUB="$(cat $WG_DIR/wg.pub)" # Client public key
WG_SRV_PUB="qAXDUfz7J2moxpTsp1jnTsP88tamegnjx9O9a4mbDUs=" # Server public key
NET_SVC="/etc/init.d/network"
FRW_SVC="/etc/init.d/firewall"
WAN_IF="$(uci show network.wan.device | awk -F"'" '{print $2}')"
WAN_GTW="$(ip addr show eth0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1 | sed 's/\.[0-9]\{1,3\}$/\.1/')"


# Install Packages #
echo "Installing Wireguard packages";
sleep 2;
opkg update && opkg install wireguard-tools kmod-wireguard luci-proto-wireguard;
echo "Wireguard packages successfully installed. Result:" 
echo "$(opkg list-installed | grep wireguard)";
sleep 2;


# Create WG Dir #                                                                                                                                                  
echo "Check Wireguard directory";
sleep 2;
if [ ! -d ${WG_DIR} ]; then
    echo "$WG_DIR directory not ready, let's create.."
    mkdir $WG_DIR
fi
echo "Successfully created $WG_DIR directory";
sleep 2;


# Generate a key pair of private and public keys #
echo "Generate a key pair of private and public keys";                                                                                                             
sleep 2;
wg genkey | tee $WG_DIR/wg.key | wg pubkey > $WG_DIR/wg.pub;
echo "Successfully generated a key pairs, result:";
sleep 2;
echo "Your private key: $WG_CLN_KEY"                                                                                                                               
echo "Your public key: $WG_CLN_PUB"                                                                                                                                
sleep 5;


# Setup Firewall #
echo "Let's Setup Firewall";
sleep 2;
uci rename firewall.@zone[0]="lan";
uci rename firewall.@zone[1]="wan";
uci add_list firewall.wan.network="${WG_IF}";
uci del_list firewall.wan.network="${WG_IF}";
uci commit firewall;
#service firewall restart &;
sleep 2;
echo "Firewall successfully configured, result: $(uci show firewall.wan.network)";
sleep 2;
echo "Restart the firewall service"
if eval $FRW_SVC status >/dev/null 2>&1; then
    echo "Firewall service state: Running";
    echo "Restarting firewall service";
    sleep 2;
    eval $FRW_SVC restart &;
    FRW_PID=$!;
    wait $FRW_PID;
    echo "Firewall service successfully restarted";
else
    echo "WTF, firewall service is dead, need to be fixed";
    exit 1
fi
sleep 2;


# Configure WG interface #                                                                                                                                         
echo "Let's configure Wireguard interface";
sleep 2;
uci -q delete network.${WG_IF};                                                                                                                                    
uci set network.${WG_IF}="interface";
uci set network.${WG_IF}.proto="wireguard";
uci set network.${WG_IF}.private_key="${WG_CLN_KEY}";
uci add_list network.${WG_IF}.addresses="${WG_ADDR}";
uci set network.wg1.metric="10";
uci set network.wg1.dns="1.1.1.1";
echo "Wireguard interface successfully configured, result: $(uci show network.\${WG_IF})";
sleep 2;


# Configure WAN interface #
uci set network.wan.metric="20";
echo "Successfully setting metric in WAN interface, result: $(uci show network.wan.metric;)";
sleep 2;


# Add VPN peers #
echo "Let's add VPN peers";
sleep 2;
uci -q delete network.wgserver;
uci set network.wgserver="wireguard_${WG_IF}";
uci set network.wgserver.public_key="${WG_SRV_PUB}";
uci set network.wgserver.endpoint_host="${WG_SERV}";
uci set network.wgserver.endpoint_port="${WG_PORT}";
uci set network.wgserver.persistent_keepalive="25";
uci set network.wgserver.route_allowed_ips="1";
uci add_list network.wgserver.allowed_ips="0.0.0.0/0";
uci commit network;
echo "VPN peers successfully added, result: $(uci show network.wgserver)";
sleep 2;


# Restart the network service #
echo "Restart the network service"
if eval $NET_SVC status >/dev/null 2>&1; then
    echo "Network service state: Running";
    echo "Restarting network service";
    sleep 2;
    eval $NET_SVC restart &;
    NET_PID=$!;
    wait $NET_PID;
    echo "Network service successfully restarted";
else
    echo "WTF, network service is dead, need to be fixed";
    exit 1
fi
sleep 5;


# Configure Routing IP #
echo "Let's configure routing IP";
sleep 2;
echo "Check routing table before";
route -n | tee ~/routing_before$(date +%Y%m%d).txt;
sleep 2;
ip route del default;
ip route add default dev $WG_IF;
ip route add 54.251.3.207/32 via $WAN_GTW dev $WAN_IF;
echo "Successfully configured routing IP, result: $(route -n)";
sleep 5;


# Restart WG Interface #
echo "Check Wireguard connection";
wg;
echo "Let's restart Wireguard interface";
sleep 2;
ifdown $WG_IF;
ifup $WG_IF;


# Check Connection #
curl ipinfo.io | tee ~/ipinfo$(date +%Y%m%d).txt;
sleep 5;
traceroute openwrt.org | tee /root/traceroute.txt;