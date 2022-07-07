#!/usr/bin/env bash
YW=`echo "\033[33m"`
RD=`echo "\033[01;31m"`
BL=`echo "\033[36m"`
GN=`echo "\033[1;92m"`
CL=`echo "\033[m"`
RETRY_NUM=10
RETRY_EVERY=3
NUM=$RETRY_NUM
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"
BFR="\\r\\033[K"
HOLD="-"
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

function msg_info() {
    local msg="$1"
    echo -ne " ${HOLD} ${YW}${msg}..."
}

function msg_ok() {
    local msg="$1"
    echo -e "${BFR} ${CM} ${GN}${msg}${CL}"
}

msg_info "Setting up Root SSH"

tmpfile="/tmp/authkeys.$$"

sed -i 's\#PermitRootLogin prohibit-password\PermitRootLogin without-password\g' /etc/ssh/sshd_config

service ssh restart

echo "Please enter a github user account to add it's SSH key to the root authorized_keys file." >&2
echo "Leave this blank if you don't want to use an ssh key. You will need to log in using the Proxmox Console." >&2
read -r githubuser

fullname=$( curl -s https://api.github.com/users/${githubuser} | jq -r '.name' )

keycomment="$fullname github:${githubuser}"

curl -s https://github.com/${githubuser}.keys >$tmpfile
if [[ $( stat -c'%s' $tmpfile ) -gt 1 ]]; then
  sed -i -e "s/$/ ${keycomment}/" $tmpfile
  cat $tmpfile >>/root/.ssh/authorized_keys
  echo >>/root/.ssh/authorized_keys
  chmod 600 /root/.ssh/authorized_keys
else
  echo "Couldn't get any keys, or you left this blank." >&2
fi

rm $tmpfile
msg_ok "Set up Root SSH"