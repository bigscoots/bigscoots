#!/bin/bash

if [[ -z $1 || -z $2 ]]; then
  echo "one or more variables are undefined."	
  exit 1
fi

RIP=$1
RHOSTNAME=$2

RLO=$(echo "${RIP}" | awk -F. '{print $4}')
PTRABBR=$(echo "${RIP}" | awk -F. '{print $3"." $2"."$1}')
PTRZONE=$(echo "${PTRABBR}".in-addr.arpa)

while whmapi1 dumpzone domain="${PTRZONE}" | grep "name: ${RLO}.${PTRZONE}" > /dev/null 2>&1; do
	DNSLINE=$(whmapi1 dumpzone domain="${PTRZONE}" | grep -B2 "name: ${RLO}.${PTRZONE}" | grep Line | awk '{print $2}' | head -1)
	slack "#ptr" ":information_source: Removing from zone=${PTRZONE} on line=${DNSLINE} for ${RIP} : ${RHOSTNAME}"
	if ! whmapi1 removezonerecord zone="${PTRZONE}" line="${DNSLINE}" > /dev/null 2>&1; then
		slack "#ptr" ":x: FAILED: Removing from zone=${PTRZONE} on line=${DNSLINE} for ${RIP} : ${RHOSTNAME}"
	else
		slack "#ptr" ":heavy_check_mark: SUCCESS: Removing from zone=${PTRZONE} on line=${DNSLINE} for ${RIP} : ${RHOSTNAME}"
	fi
done

if ! whmapi1 dumpzone domain="${PTRZONE}" | grep -q "name: ${RLO}.${PTRZONE}" > /dev/null 2>&1; then
	slack "#ptr" ":information_source: Adding to zone=${PTRZONE} for ${RIP} : ${RHOSTNAME}"
	if ! whmapi1 addzonerecord zone="${PTRZONE}" name="${RLO}" ptrdname="${RHOSTNAME}" type=PTR > /dev/null 2>&1; then
		slack "#ptr" ":x: FAILED: Adding to zone=${PTRZONE} for ${RIP} : ${RHOSTNAME}"
	else
		slack "#ptr" ":heavy_check_mark: SUCCESS: Adding to zone=${PTRZONE} for ${RIP} : ${RHOSTNAME} \n \n"
	fi
fi
