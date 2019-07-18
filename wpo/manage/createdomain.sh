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

if [ -d /home/nginx/domains/"$domain" ]; then
  echo "$domain already exists on the server."
  exit 1
fi

if [ "$2" == fresh ]; then
  /bigscoots/wpo/manage/expect/createdomain "$domain"
  cd /home/nginx/domains/"$domain"/public || exit
  bash /bigscoots/wpo_theworks.sh fresh

else

  /bigscoots/wpo/manage/expect/createdomain "$domain"

fi