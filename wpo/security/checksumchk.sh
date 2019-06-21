#!/bin/bash
# BigScoots checksums

for wpinstall in /home/nginx/domains/*/public ; do

/bin/wp core verify-checksums --allow-root --skip-plugins --skip-themes --path="$wpinstall" >/dev/null 2>&1

checksumexitcode=$?

if [ $checksumexitcode -ne 0 ]; then
    /bin/wp core verify-checksums --allow-root --skip-plugins --skip-themes --path="$wpinstall" 2>&1 | mail -s "WordPress Core Checksum failed: $wpinstall" monitor@bigscoots.com
fi

/bin/wp plugin verify-checksums --all --allow-root --skip-plugins --skip-themes --path="$wpinstall" >/dev/null 2>&1

checksumexitcode=$?

if [ $checksumexitcode -ne 0 ]; then
   /bin/wp plugin verify-checksums --all --allow-root --skip-plugins --skip-themes --path="$wpinstall" 2>&1 | mail -s "WordPress Plugins Checksum failed: $wpinstall" monitor@bigscoots.com
fi

done
