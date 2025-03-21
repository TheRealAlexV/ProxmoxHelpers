#!/usr/bin/env bash
echo -e "\e[1;33m This script will install Home Assistant Community Store (HACS)  \e[0m"

while true; do
    read -p "Start the HACS Install Script (y/n)?" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

apt update &>/dev/null
apt install unzip &>/dev/null
cd /var/lib/docker/volumes/hass_config/_data
wget -O - https://get.hacs.xyz | bash -

# To install HACS run the following from the container (LXC) console
# bash -c "$(wget -qLO - https://raw.githubusercontent.com/TheRealAlexV/ProxmoxHelpers/main/misc/hacs.sh)"
# Then add the integration in HA
