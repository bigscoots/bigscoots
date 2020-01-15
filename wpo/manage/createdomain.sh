#!/bin/bash

if [ -z "$1" ]; then
  echo "Requires a domain."
  exit 1
fi

# if [ -z "$2" ]; then
#   echo "Requires fresh or existing."
#   exit 1
# fi

domain="$1"
ftpuser="${domain//./}"
email=admin@"$domain"

if [[ ${domain} == *"bigscoots-staging"* ]]; then
    email=admin@"$(echo $domain | sed '/\..*\./s/^[^.]*\.//')"
fi

domainip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1\|192.168.')

if [ -d /home/nginx/domains/"$domain" ]; then
  echo "$domain already exists on the server."
  exit 1
fi

if [ "$2" == fresh ]; then
  /bigscoots/wpo/manage/expect/createdomain "$domain" "$ftpuser" "$email"
  cd /home/nginx/domains/"$domain"/public || exit
  bash /bigscoots/wpo_theworks.sh fresh

else

  /bigscoots/wpo/manage/expect/createdomain "$domain" "$ftpuser" "$email"

fi

sed "s/REPLACEDOMAIN/$domain/g ; s/REPLACEIP/$domainip/g" /bigscoots/wpo/extras/dnszone.txt > /home/nginx/domains/"$domain"/"$domain"-dnszone.txt

if [ -f /home/nginx/domains/"$domain"/.fresh ]; then
  cat /home/nginx/domains/"$domain"/.fresh | mail -s "$domain has been successfully created on  $HOSTNAME - DNS attached" -a /home/nginx/domains/"$domain"/"$domain"-dnszone.txt monitor@bigscoots.com
else
  echo "" | mail -s "$domain has been successfully created on  $HOSTNAME - DNS attached" -a /home/nginx/domains/"$domain"/"$domain"-dnszone.txt monitor@bigscoots.com
fi