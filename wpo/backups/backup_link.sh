#!/bin/bash

# Generate backup and provide a link that expires after 48 hours.

RANDO1=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 16 | head -n 1)
RANDO2=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 16 | head -n 1)
BACKUP=$1

if [ -z "${BACKUP}" ]; then 
	echo "need filename"
	exit
fi

if [[ $2 == local ]]; then
	mkdir -p /usr/local/nginx/html/"${RANDO1}"/"${RANDO2}"/
	ln -s "${PWD}"/"${BACKUP}" /usr/local/nginx/html/"${RANDO1}"/"${RANDO2}"/"${BACKUP}"
	screen -dmS "${BACKUP}" bash -c "sleep 172800 ; [ -d /usr/local/nginx/html/${RANDO1} ] && rm -rf /usr/local/nginx/html/${RANDO1} ; [ -f ${PWD}/${BACKUP} ] && rm -f ${PWD}/${BACKUP}"

	echo "Path: ${PWD}/${BACKUP}"
	echo "Sympath: /usr/local/nginx/html/${RANDO1}/${RANDO2}/${BACKUP}"
	link="https://$HOSTNAME/${RANDO1}/${RANDO2}/${BACKUP}"
else

	mkdir -p /var/www/html/"${RANDO1}"/"${RANDO2}"/
	mv "${BACKUP}" /var/www/html/"${RANDO1}"/"${RANDO2}"/

	screen -dmS "${BACKUP}" bash -c "sleep 172800 ; rm -rf /var/www/html/${RANDO1}"

	# echo "Path: /var/www/html/${RANDO1}/${RANDO2}/${BACKUP}"
	link="http://$HOSTNAME/${RANDO1}/${RANDO2}/${BACKUP}"

	downloadinfo="DownloadLink
	$link"
	
	  jq -Rn '
	( input  | split("|") ) as $keys |
	( inputs | split("|") ) as $vals |
	[[$keys, $vals] | transpose[] | {key:.[0],value:.[1]}] | from_entries
	' <<<"$downloadinfo"
fi