#!/bin/bash

DOMAIN=$1

if [ -d /home/nginx/domains/"${DOMAIN}" ]; then
  chown -R nginx: /home/nginx/domains/"${DOMAIN}" > /dev/null 2>&1
  find /home/nginx/domains/"${DOMAIN}" -type f -exec chmod 644 {} \; > /dev/null 2>&1
  find /home/nginx/domains/"${DOMAIN}" -type d -exec chmod 755 {} \; > /dev/null 2>&1
fi
