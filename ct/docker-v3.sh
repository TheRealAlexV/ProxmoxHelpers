#!/usr/bin/env bash
source "$HOME/ProxmoxScripts/.ProxmoxHelpers/config.sh"
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
APP="Docker"
NSAPP=$(echo ${APP,,} | tr -d ' ')
set -o errexit
set -o errtrace
#set -o nounset
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
echo -e "${BL}
  _____             _             
 |  __ \           | |            
 | |  | | ___   ___| | _____ _ __ 
 | |v3| |/ _ \ / __| |/ / _ \  __|
 | |__| | (_) | (__|   <  __/ |   
 |_____/ \___/ \___|_|\_\___|_|   
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
        echo -e "${DGN}Using CT Type ${BGN}Unprivileged${CL} ${RD}NO DEVICE PASSTHROUGH${CL}"
        CT_TYPE="1"
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
        echo -e "${DGN}Using ${BGN}2048${CL}${DGN}MiB RAM${CL}"
        RAM_SIZE="2048"
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
        echo -e "${YW}Type Privileged, or Press [ENTER] for Default: Unprivileged (${RD}NO DEVICE PASSTHROUGH${CL}${YW})"
        read CT_TYPE1
        if [ -z $CT_TYPE1 ]; then CT_TYPE1="Unprivileged" CT_TYPE="1"; 
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
        echo -e "${YW}Allocate RAM in MiB, or Press [ENTER] for Default: 2048 "
        read RAM_SIZE
        if [ -z $RAM_SIZE ]; then RAM_SIZE="2048"; fi;
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
        echo -e "${YW}How would you like to Assign the IP address?"
        echo -e "${YW}Enter \"DHCP\" for DHCP, or just press [ENTER] for Auto Selection from Netbox"
        echo -e "${YW}Or just enter a Static IPv4 CIDR Address to manually specify:  "
        read NET
        if [ -z $NET ]; then 
                echo "[1] 10.100.0.0/22 (Infra)"
                echo "[14] 10.104.2.0/23 (DeMiNe0)"
                echo "[15] 10.104.4.0/23 (VaninoLLC)"
                echo "[16] 10.200.0.0/23 (Infra-DMZ)"
                echo "[17] 10.200.2.0/23 (DeMiNe0-DMZ)"
                echo "[18] 10.200.4.0/23 (VaninoLLC-DMZ)"
                echo ""
                echo "Enter the number corresponding to the Prefix you would like to use from above."
                read -r NBPREFIX
                NET=$(curl -X GET \
                -H "Authorization: Token $NBTOKEN" \
                -H "Content-Type: application/json" \
                -H "Accept: application/json; indent=4" \
                "$NBADDR/api/ipam/prefixes/$NBPREFIX/available-ips/?limit=1" \
                | jq -r '.[].address')
                case $NBPREFIX in
                  "1")
                    NETNAME="INF"
                  ;;
                  "14")
                    NETNAME="DEM"
                  ;;
                  "15")
                    NETNAME="VLC"
                  ;;
                  "16")
                    NETNAME="INFDMZ"
                  ;;
                  "17")
                    NETNAME="DEMDMZ"
                  ;;
                  "18")
                    NETNAME="VLCDMZ"
                  ;;
                esac    
        elif [ $NET == 'dhcp' ]; then
                NET="dhcp";
        fi;
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
        if [ ! -z $NBPREFIX ]; then
          case $NBPREFIX in
            "1")
              GATE1="10.100.0.1"
              GATE=",gw=$GATE1"
            ;;
            "14")
              GATE1="10.104.2.1"
              GATE=",gw=$GATE1"
            ;;
            "15")
              GATE1="10.104.4.1"
              GATE=",gw=$GATE1"
            ;;
            "16")
              GATE1="10.200.0.1"
              GATE=",gw=$GATE1"
            ;;
            "17")
              GATE1="10.200.2.1"
              GATE=",gw=$GATE1"
            ;;
            "18")
              GATE1="10.200.4.0"
              GATE=",gw=$GATE1"
            ;;
          esac
          echo -en "${DGN}Set Gateway IP To ${BL}$GATE1${CL}"
        else        
          echo -e "${YW}Enter a Gateway IP (mandatory if static IP is used), or Press [ENTER] for Default: NONE "
          read GATE1
          if [ -z $GATE1 ]; then GATE1="NONE" GATE=""; 
            echo -en "${DGN}Set Gateway IP To ${BL}$GATE1${CL}"
          else
            GATE=",gw=$GATE1"
            echo -en "${DGN}Set Gateway IP To ${BL}$GATE1${CL}"
          fi;
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
        if [ ! -z $NBPREFIX ]; then
          case $NBPREFIX in
            "1")
              VLAN1="NONE"
              VLAN=""
            ;;
            "14")
              VLAN1="50"
              VLAN=",tag=$VLAN1"
            ;;
            "15")
              VLAN1="52"
              VLAN=",tag=$VLAN1"
            ;;
            "16")
              VLAN1="2"
              VLAN=",tag=$VLAN1"
            ;;
            "17")
              VLAN1="51"
              VLAN=",tag=$VLAN1"
            ;;
            "18")
              VLAN1="53"
              VLAN=",tag=$VLAN1"
            ;;
          esac
          echo -en "${DGN}Set VLAN Tag To ${BL}$VLAN1${CL}"
        else  
          echo -e "${YW}Enter a VLAN Tag, or Press [ENTER] for Default: NONE "
          read VLAN1
          if [ -z $VLAN1 ]; then VLAN1="NONE" VLAN=""; 
            echo -en "${DGN}Set VLAN Tag To ${BL}$VLAN1${CL}"
          else
            VLAN=",tag=$VLAN1"
          echo -en "${DGN}Set VLAN Tag To ${BL}$VLAN1${CL}"
          fi;
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
        echo -e "${YW}Enter a Domain Name (Without Host), or Press [ENTER] for Default: NONE "
        read DOMAIN1
        if [ -z $DOMAIN1 ]; then DOMAIN1="" DOMAIN=""; 
        echo -en "${DGN}Set DOMAIN (without Host) To ${BL}$DOMAIN1${CL}"
        else
          DOMAIN=",tag=$DOMAIN1"
        echo -en "${DGN}Set DOMAIN (without Host) To ${BL}$DOMAIN1${CL}"
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
        echo -e "${DGN}Using DOMAIN ${BGN}$DOMAIN1${CL}"
        echo -e "${YW}Enter a Host Name (Without Domain), or Press [ENTER] for Default: NONE "
        read HOSTNAME1
        if [ -z $HOSTNAME1 ]; then HOSTNAME1="" HOSTNAME=""; 
        echo -en "${DGN}Set HOST (without Domain) To ${BL}$HOSTNAME1${CL}"
        else
          HOSTNAME=",tag=$HOSTNAME1"
        echo -en "${DGN}Set HOST (without Domain) To ${BL}$HOSTNAME1${CL}"
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
        echo -e "${DGN}Using DOMAIN ${BGN}$DOMAIN1${CL}"
        echo -e "${DGN}Using HOST ${BGN}$HOSTNAME1${CL}"

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
EOF

msg_info "Starting LXC Container"
pct start $CTID
msg_ok "Started LXC Container"

lxc-attach -n $CTID -- bash -c "$(wget -qLO - https://raw.githubusercontent.com/TheRealAlexV/ProxmoxHelpers/main/setup/docker-install.sh)" || exit
lxc-attach -n $CTID -- bash -c "$(wget -qLO - https://raw.githubusercontent.com/TheRealAlexV/ProxmoxHelpers/main/misc/root-ssh.sh)" || exit

IP=$(pct exec $CTID ip a s dev eth0 | sed -n '/inet / s/\// /p' | awk '{print $2}')

source <(curl -s https://raw.githubusercontent.com/TheRealAlexV/ProxmoxHelpers/main/misc/register-infra.sh)

msg_ok "Completed Successfully!\n"
