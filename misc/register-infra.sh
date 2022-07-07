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
"$NBADDR/api/ipam/ip-addresses/" \
--data "$(post_data)"

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
"$PFADDR/api/v1/services/unbound/host_override" \
-H "Authorization: $PFCID $PFTOKEN" \
-H 'accept: application/json' \
-H 'Content-Type: application/json' \
--data "$(post_data)"
