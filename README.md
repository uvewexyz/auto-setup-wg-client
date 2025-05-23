# Descriptions
You can use the `setup_wan_if.sh` script to initiate auto setup of the WAN interface and then use the `setup_wg_client.sh` script to start the WireGuard client setup automatically in your `OpenWRT VM`.

# Contents
- `setup_wan_if.sh`
- `setup_wg_client.sh`

# How to use it?
1. Firstly, download both scripts in this repository
```bash
wget https://raw.githubusercontent.com/uvewexyz/auto-setup-wg-client/refs/heads/main/setup_wan_if.sh && wget https://raw.githubusercontent.com/uvewexyz/auto-setup-wg-client/refs/heads/main/setup_wg_client.sh
```
```bash
ls -l
```

2. Grant executable permission to both scripts
```bash
chmod +x setup_w* && ls -l
```

3. Initiate with running the `setup_wan_if.sh` script. Because the eth0 or the interface connection(outbound) to my bridge doesn't have an IP address

![setup_wan_if](https://github.com/user-attachments/assets/1e1205b6-9e4d-46ac-b3f4-ca01eabff091)

4. If you are successfully running the `setup_wan_if.sh` script and not the error output. Next, run the `setup_wg_client.sh` and remember to customize the var in the script and match the var with your WG server

![setup_wg_client](https://github.com/user-attachments/assets/cbf020a8-2d1f-403b-bebc-8135757787d6)

5. Done
