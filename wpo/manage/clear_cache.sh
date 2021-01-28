#!/bin/bash

# Cache Control

if [[ -z $1 || -z $2 ]]; then
  echo "one or more variables are undefined."	
  exit 1
fi

DOMAIN="$1"
# WPCLIFLAGS="--allow-root --skip-plugins --skip-themes --require=/bigscoots/includes/err_report.php"

case $2 in
page_cache)

# /bigscoots/wpo/manage/clear_cache.sh "${DOMAIN}" page_cache

rm -rf /home/nginx/domains/"${DOMAIN}"/public/wp-content/cache/*

if REDIS=$(which redis-cli) >/dev/null 2>&1; then
	if ! "${REDIS}" flushall >/dev/null 2>&1; then 
		exit 0
	else
		exit 0
	fi
fi

;;
object_cache)

# /bigscoots/wpo/manage/clear_cache.sh "${DOMAIN}" object_cache

# no setup yet
exit 0

;;
op_cache)

# /bigscoots/wpo/manage/clear_cache.sh "${DOMAIN}" op_cache

/bin/fpmreload >/dev/null 2>&1

exit 0

;;
all_cache)

# /bigscoots/wpo/manage/clear_cache.sh "${DOMAIN}" all_cache

rm -rf /home/nginx/domains/"${DOMAIN}"/public/wp-content/cache/* 

if REDIS=$(which redis-cli) >/dev/null 2>&1; then
	if ! "${REDIS}" flushall >/dev/null 2>&1; then 
		exit 0
	else
		exit 0
	fi
fi

;;
cloudflare_cache)

# /bigscoots/wpo/manage/clear_cache.sh "${DOMAIN}" cloudflare_cache

# no setup yet
exit 0

;;
esac