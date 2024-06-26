#!/bin/bash
# Cloudflare as Dynamic DNS
# From: https://nickperanzi.com/blog/cloudflare-ddns-with-token/
# Based on: https://letswp.io/cloudflare-as-dynamic-dns-raspberry-pi/
# Based on: https://gist.github.com/benkulbertis/fff10759c2391b6618dd/
# Original non-RPi article: https://phillymesh.net/2016/02/23/setting-up-dynamic-dns-for-your-registered-domain-through-cloudflare/

# Update these with real values
auth_token="paste-api-token-here"
zone_id="paste-zone-id-here"
record_name="vpn.yourdomain.com"

# Don't touch these
# Default http://api.ipify.org  
#curl ifconfig.me
#curl ipv4.ip.sb
#curl http://test.ipw.cn
#https://icanhazip.com/
#http://ident.me/
ip=$(curl -s http://api.ipify.org )
ip_file="ip.txt"
log_file="cloudflare.log"

# Keep files in the same folder when run from cron
current="$(pwd)"
cd "$(dirname "$(readlink -f "$0")")"

log() {
    if [ "$1" ]; then
        echo -e "[$(date)] - $1" >> $log_file
    fi
}

log "Check Initiated"

if [ -f $ip_file ]; then
    old_ip=$(cat $ip_file)
    if [ $ip == $old_ip ]; then
        log "IP has not changed."
        exit 0
    fi
fi

#get the domain and authentic
record_identifier=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records?type=${record_type}&name=$record_name" \
        -H "Authorization: Bearer $auth_token" \
        -H "Content-Type: application/json"  | grep -Po '(?<="id":")[^"]*')
# overwrite the dns
update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_identifier/dns_records/$record_identifier" \
    -H "Authorization: Bearer $auth_token" \
    -H "Content-Type: application/json" \
    --data "{\"type\":\"$record_type\",\"name\":\"$record_name\",\"content\":\"$ip\",\"ttl\":600,\"proxied\":false}")


#gave the feedback about the update statues
if [[ $update == *"\"success\":true"* ]]; then
    message="IP changed to: $ip"
    echo "$ip" > $ip_file
    log "$message"
    echo "$message"
else
    message="API UPDATE FAILED. DUMPING RESULTS:\n$update"
    log "$message"
    echo -e "$message"
    exit 1
fi
