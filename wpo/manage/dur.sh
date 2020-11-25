#!/bin/bash

# DUR - https://github.com/amekkawi/diskusagereports

DATE=$(date +'%m%d%Y%H%M')
DURL="https://${HOSTNAME}/diskusagereports/?${DATE}/"

if [ ! -d /usr/local/nginx/html/diskusagereports ]; then 
	git clone https://github.com/jcatello/diskusagereports /usr/local/nginx/html/diskusagereports > /dev/null 2>&1
fi

bash /usr/local/nginx/html/diskusagereports/scripts/find.sh /home/nginx/domains | php -d error_reporting=0 /usr/local/nginx/html/diskusagereports/scripts/process.php /usr/local/nginx/html/diskusagereports/data/"${DATE}" > /dev/null 2>&1

echo { \"disk_usage_url\": "\"${DURL}\"", \"disk_usage_date\": "\"${DATE}\"" }