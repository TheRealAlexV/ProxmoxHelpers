#!/usr/bin/env bash
NEXTID=$(pvesh get /cluster/nextid)
INTEGER='^[0-9]+$'
YW=`echo "\033[33m"`
BL=`echo "\033[36m"`
RD=`echo "\033[01;31m"`
BGN=`echo "\033[4;92m"`
GN=`echo "\033[1;92m"`
DGN=`echo "\033[32m"`
CL=`echo "\033[m"`
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"
APP="Zigbee2MQTT"
NSAPP=$(echo ${APP,,} | tr -d ' ')
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
shopt -s expand_aliases
alias die='EXIT=$? LINE=$LINENO error_exit'
trap die ERR

function error_exit() {
  trap - ERR
  local reason="Unknown failure occured."
  local msg="${1:-$reason}"
  local flag="${RD}‼ ERROR ${CL}$EXIT@$LINE"
  echo -e "$flag $msg" 1>&2
  exit $EXIT
}

while true; do
    read -p "This will create a New ${APP} LXC. Proceed(y/n)?" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
clear
function header_info {
echo -e "${YW}
  _______       _               ___  __  __  ____ _______ _______ 
 |___  (_)     | |             |__ \|  \/  |/ __ \__   __|__   __|
    / / _  __ _| |__   ___  ___   ) | \  / | |  | | | |     | |   
   / / | |/ _  |  _ \ / _ \/ _ \ / /| |\/| | |  | | | |     | |   
  / /__| | (_| | |_) |  __/  __// /_| |  | | |__| | | |     | |   
 /_____|_|\__, |____/ \___|\___|____|_|  |_|\___\_\ |_|     |_|   
        v3 __/ |                                                  
          |___/                                                   
${CL}"
}

header_info

function msg_info() {
    local msg="$1"
    echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
    local msg="$1"
    echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

function PVE_CHECK() {
    PVE=$(pveversion | grep "pve-manager/7" | wc -l)

    if [[ $PVE != 1 ]]; then
        echo -e "${RD}This script requires Proxmox Virtual Environment 7.0 or greater${CL}"
        echo -e "Exiting..."
        sleep 2
        exit
    fi
}

function default_settings() {
        clear
        header_info
        echo -e "${BL}Using Default Settings${CL}"
        echo -e "${DGN}Using CT Type ${BGN}Privileged${CL}"
        CT_TYPE="0"
        echo -e "${DGN}Using CT Password ${BGN}Automatic Login${CL}"
        PW=" "
        echo -e "${DGN}Using CT ID ${BGN}$NEXTID${CL}"
        CT_ID=$NEXTID
        echo -e "${DGN}Using CT Name ${BGN}$NSAPP${CL}"
        HN=$NSAPP
        echo -e "${DGN}Using Disk Size ${BGN}4${CL}${DGN}GB${CL}"
        DISK_SIZE="4"
        echo -e "${DGN}Using ${BGN}2${CL}${DGN}vCPU${CL}"
        CORE_COUNT="2"
        echo -e "${DGN}Using ${BGN}1024${CL}${DGN}MiB RAM${CL}"
        RAM_SIZE="1024"
        echo -e "${DGN}Using Bridge ${BGN}vmbr0${CL}"
        BRG="vmbr0"
        echo -e "${DGN}Using Static IP Address ${BGN}DHCP${CL}"
        NET=dhcp
        echo -e "${DGN}Using Gateway Address ${BGN}NONE${CL}"
        GATE=""
        echo -e "${DGN}Using VLAN Tag ${BGN}NONE${CL}"
        VLAN=""
}

function advanced_settings() {
        clear
        header_info
        echo -e "${RD}Using Advanced Settings${CL}"
        echo -e "${YW}Type ${CROSS}${YW}Unprivileged, or Press [ENTER] for Default: Privileged"
        read CT_TYPE1
        if [ -z $CT_TYPE1 ]; then CT_TYPE1="Privileged" CT_TYPE="0"; 
        echo -en "${DGN}Set CT Type ${BL}$CT_TYPE1${CL}"
        else
        CT_TYPE1="Privileged"
        CT_TYPE="0"
        echo -en "${DGN}Set CT Type ${BL}Privileged${CL}"  
        fi;
echo -e " ${CM}${CL} \r"
sleep 1
clear
header_info
        echo -e "${RD}Using Advanced Settings${CL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${CL}"
        echo -e "${YW}Set Password, or Press [ENTER] for Default: Automatic Login "
        read PW1
        if [ -z $PW1 ]; then PW1="Automatic Login" PW=" "; 
        echo -en "${DGN}Set CT ${BL}$PW1${CL}"
        else
          PW="-password $PW1"
        echo -en "${DGN}Set CT Password ${BL}$PW1${CL}"
        fi;
echo -e " ${CM}${CL} \r"
sleep 1
clear
header_info
        echo -e "${RD}Using Advanced Settings${CL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${CL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${CL}"
        echo -e "${YW}Enter the CT ID, or Press [ENTER] to automatically generate (${NEXTID}) "
        read CT_ID
        if [ -z $CT_ID ]; then CT_ID=$NEXTID; fi;
        echo -en "${DGN}Set CT ID To ${BL}$CT_ID${CL}"
echo -e " ${CM}${CL} \r"
sleep 1
clear
header_info
        echo -e "${RD}Using Advanced Settings${CL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${CL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${CL}"
        echo -e "${DGN}Using CT ID ${BGN}$CT_ID${CL}"
        echo -e "${YW}Enter CT Name (no-spaces), or Press [ENTER] for Default: $NSAPP "
        read CT_NAME
        if [ -z $CT_NAME ]; then
           HN=$NSAPP
        else
           HN=$(echo ${CT_NAME,,} | tr -d ' ')
        fi
        echo -en "${DGN}Set CT Name To ${BL}$HN${CL}"
echo -e " ${CM}${CL} \r"
sleep 1
clear
header_info
        echo -e "${RD}Using Advanced Settings${CL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${CL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${CL}"
        echo -e "${DGN}Using CT ID ${BGN}$CT_ID${CL}"
        echo -e "${DGN}Using CT Name ${BGN}$HN${CL}"
        echo -e "${YW}Enter a Disk Size, or Press [ENTER] for Default: 4 "
        read DISK_SIZE
        if [ -z $DISK_SIZE ]; then DISK_SIZE="4"; fi;
        if ! [[ $DISK_SIZE =~ $INTEGER ]] ; then echo "ERROR! DISK SIZE MUST HAVE INTEGER NUMBER!"; exit; fi;
        echo -en "${DGN}Set Disk Size To ${BL}$DISK_SIZE${CL}${DGN}GB${CL}"
echo -e " ${CM}${CL} \r"
sleep 1
clear
header_info
        echo -e "${RD}Using Advanced Settings${CL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${CL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${CL}"
        echo -e "${DGN}Using CT ID ${BGN}$CT_ID${CL}"
        echo -e "${DGN}Using CT Name ${BGN}$HN${CL}"
        echo -e "${DGN}Using Disk Size ${BGN}$DISK_SIZE${CL}${DGN}GB${CL}"
        echo -e "${YW}Allocate CPU cores, or Press [ENTER] for Default: 2 "
        read CORE_COUNT
        if [ -z $CORE_COUNT ]; then CORE_COUNT="2"; fi;
        echo -en "${DGN}Set Cores To ${BL}$CORE_COUNT${CL}${DGN}vCPU${CL}"
echo -e " ${CM}${CL} \r"
sleep 1
clear
header_info
        echo -e "${RD}Using Advanced Settings${CL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${CL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${CL}"
        echo -e "${DGN}Using CT ID ${BGN}$CT_ID${CL}"
        echo -e "${DGN}Using CT Name ${BGN}$HN${CL}"
        echo -e "${DGN}Using Disk Size ${BGN}$DISK_SIZE${CL}${DGN}GB${CL}"
        echo -e "${DGN}Using ${BGN}${CORE_COUNT}${CL}${DGN}vCPU${CL}"
        echo -e "${YW}Allocate RAM in MiB, or Press [ENTER] for Default: 1024 "
        read RAM_SIZE
        if [ -z $RAM_SIZE ]; then RAM_SIZE="1024"; fi;
        echo -en "${DGN}Set RAM To ${BL}$RAM_SIZE${CL}${DGN}MiB RAM${CL}"
echo -e " ${CM}${CL} \n"
sleep 1
clear
header_info
        echo -e "${RD}Using Advanced Settings${CL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${CL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${CL}"
        echo -e "${DGN}Using CT ID ${BGN}$CT_ID${CL}"
        echo -e "${DGN}Using CT Name ${BGN}$HN${CL}"
        echo -e "${DGN}Using Disk Size ${BGN}$DISK_SIZE${CL}${DGN}GB${CL}"
        echo -e "${DGN}Using ${BGN}${CORE_COUNT}${CL}${DGN}vCPU${CL}"
        echo -e "${DGN}Using ${BGN}${RAM_SIZE}${CL}${DGN}MiB RAM${CL}"
        echo -e "${YW}Enter a Bridge, or Press [ENTER] for Default: vmbr0 "
        read BRG
        if [ -z $BRG ]; then BRG="vmbr0"; fi;
        echo -en "${DGN}Set Bridge To ${BL}$BRG${CL}"
echo -e " ${CM}${CL} \n"
sleep 1
clear
header_info
        echo -e "${RD}Using Advanced Settings${CL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${CL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${CL}"
        echo -e "${DGN}Using CT ID ${BGN}$CT_ID${CL}"
        echo -e "${DGN}Using CT Name ${BGN}$HN${CL}"
        echo -e "${DGN}Using Disk Size ${BGN}$DISK_SIZE${CL}${DGN}GB${CL}"
        echo -e "${DGN}Using ${BGN}${CORE_COUNT}${CL}${DGN}vCPU${CL}"
        echo -e "${DGN}Using ${BGN}${RAM_SIZE}${CL}${DGN}MiB RAM${CL}"
    	echo -e "${DGN}Using Bridge ${BGN}${BRG}${CL}"
        echo -e "${YW}Enter a Static IPv4 CIDR Address, or Press [ENTER] for Default: DHCP "
        read NET
        if [ -z $NET ]; then NET="dhcp"; fi;
        echo -en "${DGN}Set Static IP Address To ${BL}$NET${CL}"
echo -e " ${CM}${CL} \n"
sleep 1
clear
header_info
    	echo -e "${RD}Using Advanced Settings${CL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${CL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${CL}"
        echo -e "${DGN}Using CT ID ${BGN}$CT_ID${CL}"
        echo -e "${DGN}Using CT Name ${BGN}$HN${CL}"
        echo -e "${DGN}Using Disk Size ${BGN}$DISK_SIZE${CL}${DGN}GB${CL}"
        echo -e "${DGN}Using ${BGN}${CORE_COUNT}${CL}${DGN}vCPU${CL}"
        echo -e "${DGN}Using ${BGN}${RAM_SIZE}${CL}${DGN}MiB RAM${CL}"
    	echo -e "${DGN}Using Bridge ${BGN}${BRG}${CL}"
        echo -e "${DGN}Using Static IP Address ${BGN}$NET${CL}"
        echo -e "${YW}Enter a Gateway IP (mandatory if static IP is used), or Press [ENTER] for Default: NONE "
        read GATE1
        if [ -z $GATE1 ]; then GATE1="NONE" GATE=""; 
        echo -en "${DGN}Set Gateway IP To ${BL}$GATE1${CL}"
        else
          GATE=",gw=$GATE1"
        echo -en "${DGN}Set Gateway IP To ${BL}$GATE1${CL}"
        fi;
echo -e " ${CM}${CL} \n"
sleep 1
clear
header_info

        echo -e "${RD}Using Advanced Settings${CL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${CL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${CL}"
        echo -e "${DGN}Using CT ID ${BGN}$CT_ID${CL}"
        echo -e "${DGN}Using CT Name ${BGN}$HN${CL}"
        echo -e "${DGN}Using Disk Size ${BGN}$DISK_SIZE${CL}${DGN}GB${CL}"
        echo -e "${DGN}Using ${BGN}${CORE_COUNT}${CL}${DGN}vCPU${CL}"
        echo -e "${DGN}Using ${BGN}${RAM_SIZE}${CL}${DGN}MiB RAM${CL}"
	echo -e "${DGN}Using Bridge ${BGN}${BRG}${CL}"
        echo -e "${DGN}Using Static IP Address ${BGN}$NET${CL}"
        echo -e "${DGN}Using Gateway IP Address ${BGN}$GATE1${CL}"
        echo -e "${YW}Enter a VLAN Tag, or Press [ENTER] for Default: NONE "
        read VLAN1
        if [ -z $VLAN1 ]; then VLAN1="NONE" VLAN=""; 
        echo -en "${DGN}Set VLAN Tag To ${BL}$VLAN1${CL}"
        else
          VLAN=",tag=$VLAN1"
        echo -en "${DGN}Set VLAN Tag To ${BL}$VLAN1${CL}"
        fi;
echo -e " ${CM}${CL} \n"
sleep 1
clear
header_info
        echo -e "${RD}Using Advanced Settings${CL}"
        echo -e "${DGN}Using CT Type ${BGN}$CT_TYPE1${CL}"
        echo -e "${DGN}Using CT Password ${BGN}$PW1${CL}"
        echo -e "${DGN}Using CT ID ${BGN}$CT_ID${CL}"
        echo -e "${DGN}Using CT Name ${BGN}$HN${CL}"
        echo -e "${DGN}Using Disk Size ${BGN}$DISK_SIZE${CL}${DGN}GB${CL}"
        echo -e "${DGN}Using ${BGN}${CORE_COUNT}${CL}${DGN}vCPU${CL}"
        echo -e "${DGN}Using ${BGN}${RAM_SIZE}${CL}${DGN}MiB RAM${CL}"
	echo -e "${DGN}Using Bridge ${BGN}${BRG}${CL}"
        echo -e "${DGN}Using Static IP Address ${BGN}$NET${CL}"
        echo -e "${DGN}Using Gateway IP Address ${BGN}$GATE1${CL}"
        echo -e "${DGN}Using VLAN Tag ${BGN}$VLAN1${CL}"

read -p "Are these settings correct(y/n)? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    advanced_settings
fi
}

function start_script() {
		echo -e "${YW}Type Advanced, or Press [ENTER] for Default Settings "
		read SETTINGS
		if [ -z $SETTINGS ]; then default_settings; 
		else
		advanced_settings 
		fi;
}

PVE_CHECK
start_script

if [ "$CT_TYPE" == "1" ]; then 
 FEATURES="nesting=1,keyctl=1"
 else
 FEATURES="nesting=1"
 fi

TEMP_DIR=$(mktemp -d)
pushd $TEMP_DIR >/dev/null

export CTID=$CT_ID
export PCT_OSTYPE=debian
export PCT_OSVERSION=11
export PCT_DISK_SIZE=$DISK_SIZE
export PCT_OPTIONS="
  -features $FEATURES
  -hostname $HN
  -net0 name=eth0,bridge=$BRG,ip=$NET$GATE$VLAN
  -onboot 1
  -cores $CORE_COUNT
  -memory $RAM_SIZE
  -unprivileged $CT_TYPE
  $PW
"
bash -c "$(wget -qLO - https://raw.githubusercontent.com/TheRealAlexV/ProxmoxHelpers/main/ct/create_lxc.sh)" || exit

LXC_CONFIG=/etc/pve/lxc/${CTID}.conf
cat <<EOF >> $LXC_CONFIG
lxc.cgroup2.devices.allow: a
lxc.cap.drop: 
lxc.cgroup2.devices.allow: c 188:* rwm
lxc.cgroup2.devices.allow: c 189:* rwm
lxc.mount.entry: /dev/serial/by-id  dev/serial/by-id  none bind,optional,create=dir
lxc.mount.entry: /dev/ttyUSB0       dev/ttyUSB0       none bind,optional,create=file
lxc.mount.entry: /dev/ttyACM0       dev/ttyACM0       none bind,optional,create=file
EOF

msg_info "Starting LXC Container"
pct start $CTID
msg_ok "Started LXC Container"

lxc-attach -n $CTID -- bash -c "$(wget -qLO - https://raw.githubusercontent.com/TheRealAlexV/ProxmoxHelpers/main/setup/zigbee2mqtt-install.sh)" || exit

IP=$(pct exec $CTID ip a s dev eth0 | sed -n '/inet / s/\// /p' | awk '{print $2}')

msg_ok "Completed Successfully!\n"
