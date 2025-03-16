#!/bin/bash
source "$HOME/ProxmoxScripts/.ProxmoxHelpers/config.sh"

echo "Adding host to netbox"
post_data()
{
  cat <<EOF
{
    "address": "$NET",
    "dns_name": "$HOSTNAME1.$DOMAIN1"
}
EOF
}
curl -s -X POST \
-H "Authorization: Token $NBTOKEN" \
-H "Content-Type: application/json" \
"$NBADDR/api/ipam/ip-addresses/" \
--data "$(post_data)" | jq

echo "Adding host to pfsense DNS"
post_data()
{
  cat <<EOF
{
    "apply": true,
    "domain": "$DOMAIN1",
    "host": "$HOSTNAME1",
    "ip": [
        "$(echo $NET | cut -d "/" -f1)"
    ]
}
EOF
}
curl -k -X 'POST' \
"$PFADDR/api/v2/services/dns_resolver/host_override" \
-H "X-API-Key: $PFTOKEN" \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
--data "$(post_data)" | jq

echo "Adding host to pfsense firewall alaises"
post_data()
{
  cat <<EOF
{
  "address": ["$(echo $NET | cut -d "/" -f1)"],
  "apply": true,
  "name": "infra_${HOSTNAME1}_${NETNAME}",
  "type": "host"
}
EOF
}
curl -k -X 'POST' \
"$PFADDR/api/v2/firewall/alias" \
-H "X-API-Key: $PFTOKEN" \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
--data "$(post_data)" | jq
