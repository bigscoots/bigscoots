#!/bin/bash

chown -R nginx: /home/nginx/domains/ > /dev/null 2>&1
find /home/nginx/domains/ -type f -exec chmod 644 {} \; > /dev/null 2>&1
find /home/nginx/domains/ -type d -exec chmod 755 {} \; > /dev/null 2>&1
