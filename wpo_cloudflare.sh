#! /bin/bash

if [[ ! -s /root/.wpocf ]]; then

  if [ -z "$1" ]; then
    echo "No CF account is setup, please enter in a domain name to be used as the primary email."
    exit 1
  else
    cfemail=bigscoots@"$1"
    cfpass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

    cfuserkey=$(curl -s https://api.cloudflare.com/host-gw.html \
    -d 'act=user_create' \
    -d 'host_key=e3471ba7eea3a19d1459332492e51679' \
    -d "cloudflare_email=$cfemail" \
    -d "cloudflare_pass=$cfpass" | sed -n -e 's/^.*user_key":"//p' | sed 's/"/ /'g | awk '{print $1}' )

    cfapikey=$(curl -s https://api.cloudflare.com/host-gw.html \
    -d 'act=user_create' \
    -d 'host_key=e3471ba7eea3a19d1459332492e51679' \
    -d "cloudflare_email=$cfemail" \
    -d "cloudflare_pass=$cfpass" | sed -n -e 's/^.*user_api_key":"//p' |
    sed 's/"/ /'g | awk '{print $1}' )

    nameservers=$(for i in $(\ls /home/nginx/domains/)  ; do
    curl -s https://api.cloudflare.com/host-gw.html \
    -d 'act=full_zone_set' \
    -d 'host_key=e3471ba7eea3a19d1459332492e51679' \
    -d "user_key=$cfuserkey" \
    -d "zone_name=$i"
    done | grep -oh "\w*.ns.cloudflare.com\w*")

  echo "\"cloudflare_username\": \"$cfemail\"," >> /root/.wpocf  ; echo "\"cloudflare_password\": \"$cfpass\"," >> /root/.wpocf  ; echo "\"cloudflare_userkey\": \"$cfuserkey\"," >> /root/.wpocf  ; echo "\"cloudflare_apikey\": \"$cfapikey\"," >> /root/.wpocf  ; read -r ns1 ns2 <<<$(echo $nameservers) >> /root/.wpocf  ; echo "\"cloudflare_nameserver_1\": \"$ns1\"," >> /root/.wpocf  ; echo "\"cloudflare_nameserver_2\": \"$(echo $ns2 | awk '{print $1}')\"" >> /root/.wpocf ; echo ; cat /root/.wpocf
  fi
else
echo hi
fi
