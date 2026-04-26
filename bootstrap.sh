#!/bin/bash

# --- INTERACTIVE CONFIG ---
echo -e "\033[1;33m>>> mstack Monolith Bootstrap (Core Core Core) <<<\033[0m"
read -p "Enter Container ID (e.g. 110): " CTID
read -p "Enter Static IP (e.g. 192.168.1.55): " RAW_IP
GW="192.168.1.1"
STORAGE="local-lvm"
BRIDGE="vmbr0"
BASE_DIR="/opt/mstack"

# Fix CIDR
[[ "$RAW_IP" != *"/"* ]] && CT_IP="${RAW_IP}/24" || CT_IP="$RAW_IP"

# --- COLOR DEFS ---
G='\033[0;32m'; Y='\033[1;33m'; NC='\033[0m'

# 1. Host Deps
apt update && apt install -y ansible sshpass curl

# 2. SSH Key Check
[ ! -f ~/.ssh/id_rsa.pub ] && ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa

# 3. Find Template
pveam update
TEMPLATE_NAME=$(pveam available | grep "debian-13" | awk '{print $2}' | head -n 1)

# 4. Create LXC (4GB RAM / 10GB Disk)
echo -e "${Y}Creating Container $CTID with 4GB RAM...${NC}"
pct create "$CTID" "local:vztmpl/$TEMPLATE_NAME" \
    --hostname mstack \
    --net0 name=eth0,bridge="$BRIDGE",ip="$CT_IP",gw="$GW" \
    --storage "$STORAGE" \
    --memory 4096 \
    --swap 512 \
    --rootfs "$STORAGE:10" \
    --password mstackpass \
    --unprivileged 1 \
    --features nesting=1 \
    --start 1

echo -e "${Y}Waiting for boot...${NC}"
sleep 20

# 5. Inject SSH
pct exec "$CTID" -- apt update
pct exec "$CTID" -- apt install -y openssh-server
pct exec "$CTID" -- systemctl enable --now ssh
pct exec "$CTID" -- bash -c "mkdir -p /root/.ssh && echo $(cat ~/.ssh/id_rsa.pub) >> /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys"

# 6. Inventory
CLEAN_IP=$(echo "$CT_IP" | cut -d'/' -f1)
echo -e "[mstack]\n$CLEAN_IP ansible_user=root" > "$BASE_DIR/hosts.ini"
ssh-keygen -f "/root/.ssh/known_hosts" -R "$CLEAN_IP" 2>/dev/null

# 7. Playbook
echo -e "${G}>>> Triggering Playbook...${NC}"
cd "$BASE_DIR"
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i hosts.ini mstack.yaml

# 8. Clean Exit & MOTD
clear
pct exec "$CTID" -- /usr/local/bin/motd_script.sh
echo -e "${G}>>> Success! Access at http://$CLEAN_IP:6767 (SABnzbd)${NC}"