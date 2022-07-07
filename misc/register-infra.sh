#!/bin/bash
source "$HOME/.ProxmoxHelpers/config.sh"

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
http://netbox.vaninollc.com/api/ipam/ip-addresses/ \
--data "$(generate_post_data)"

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
'https://10.100.0.1/api/v1/services/unbound/host_override' \
-H "Authorization: $PFCID $PFTOKEN" \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
--data "$(generate_post_data)"
