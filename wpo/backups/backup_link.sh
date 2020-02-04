#!/bin/bash

# Generate backup and provide a link that expires after 48 hours.

rando1=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 16 | head -n 1)
rando2=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 16 | head -n 1)
backup=$1

if [ -z "$backup" ]; then 
	echo "need filename"
	exit
fi

mkdir -p /var/www/html/"$rando1"/"$rando2"/
mv "$backup" /var/www/html/"$rando1"/"$rando2"/

screen -dmS "$backup" bash -c "sleep 172800 ; rm -rf /var/www/html/$rando1"

echo "Path: /var/www/html/$rando1/$rando2/$backup"
link="$(http://$HOSTNAME/$rando1/$rando2/$backup)"

downloadinfo="DownloadLink
$link"

  jq -Rn '
( input  | split("|") ) as $keys |
( inputs | split("|") ) as $vals |
[[$keys, $vals] | transpose[] | {key:.[0],value:.[1]}] | from_entries
' <<<"$backupinfo"