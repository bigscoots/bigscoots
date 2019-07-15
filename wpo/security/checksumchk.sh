#!/bin/bash
# BigScoots checksums

for wpinstall in /home/nginx/domains/*/public ; do

wp core verify-checksums --allow-root --skip-plugins --skip-themes --path="$wpinstall" >/dev/null 2>&1

checksumexitcode=$?
domain=$(echo $wpinstall | sed 's/\/home\/nginx\/domains\///g' | sed 's/\/public//g')

if [ $checksumexitcode -ne 0 ]; then
    wp core verify-checksums --allow-root --skip-plugins --skip-themes --path="$wpinstall" 2>&1 | mail -s "WordPress Core Checksum failed: $domain" monitor@bigscoots.com
fi

wp plugin verify-checksums --all --allow-root --skip-plugins --skip-themes --path="$wpinstall" >/dev/null 2>&1

checksumexitcode=$?

if [ $checksumexitcode -ne 0 ]; then
   wp plugin verify-checksums --all --allow-root --skip-plugins --skip-themes --path="$wpinstall" 2>&1 | mail -s "WordPress Plugins Checksum failed: $domain" monitor@bigscoots.com
fi

done
