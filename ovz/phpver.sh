#!/bin/bash
# List out PHP versions on each VM outside of latest.

for CTID in $(/usr/sbin/vzlist -H -o ctid|awk '{print $1;}')
	do 
		phpver=$(vzctl exec "$CTID" "php -v" | head -1)
		if [[ ${phpver} != *"7.2"* ]] 
		then 
		echo "$CTID - $phpver"
		fi 
	done
