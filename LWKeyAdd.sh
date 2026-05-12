#!/bin/bash
## LWKeygen v1.2
## Written by JEaton and Gemini
## Updated 20260326

# Ensure pwgen is installed, otherwise generate a random string using openssl
get_passphrase() {
    if command -v pwgen >/dev/null 2>&1; then
        pwgen -snB 20 -1
    else
        openssl rand -base64 15
    fi
}

# 1. Prompt for variables
read -p "User [lwadmin-*]: " uname
uname=${uname:-lwadmin}
read -p "Hostname: " hostname
read -p "IP Address: " ip
read -p "Port [22]: " port
port=${port:-22}
read -p "UUID: " uuid

#user="lwadmin-$uuid"
    if [ "$uname" != "lwadmin" ]; then
	user="$uname"
    else
	user="lwadmin-$uuid"
    fi
pph=$(get_passphrase)
key_path="$HOME/.ssh/$hostname-$uuid.key"
key="$hostname-$uuid.key"

# 2. Confirm variables
echo  -e "]n\n--- Review Configuration ---"
echo "Hostname:   $hostname"
echo "IP:         $ip"
echo "Port:       $port"
echo "UUID:       $uuid"
echo "User:       $user"
echo "Key Path:   ~/.ssh/$key"
echo "Passphrase: $pph"
echo "----------------------------"

read -p "Is this correct? (y/n): " confirm
if [[ $confirm != [yY] ]]; then
    echo "Aborting."
    exit 1
fi

# 3. Execute SSH Key Generation
ssh-keygen -t ed25519 -C "Access for Liquid Web support team" -f "$key_path" -P "$pph"

# 4. Output Billing Note & Server Commands
echo -e "\n\n\n========================================================"
echo "BILLING NOTE (Copy to Workstation Terminal):"
echo "========================================================"
echo
cat <<EOF
cat <<EOM > ~/.ssh/$key
$(cat "$key_path")
EOM

chmod 600 ~/.ssh/$key
ssh $user@$ip -p $port -i ~/.ssh/$key

Passphrase: $pph
EOF
echo
#### TODO Adjust output based on the user provided
echo "========================================================"

echo -e "\n\n========================================================"
echo "SERVER COMMANDS (Copy to Server Terminal):"
echo "========================================================"
echo 'ssh_dir=$(getent passwd '$user' | cut -d: -f6)/.ssh'
cat <<EOF
mkdir -pv \$ssh_dir
cat <<EOM >>\$ssh_dir/authorized_keys
$(cat "$key_path.pub")
EOM

chown -R $user: \$ssh_dir
chmod 700 \$ssh_dir
chmod 600 \$ssh_dir/authorized_keys
EOF
echo
echo "========================================================"
